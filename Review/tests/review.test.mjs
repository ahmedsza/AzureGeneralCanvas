import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { CHECKLIST, CONTROLS, pillarScores, headlineScores, validateRegister } from "../checklist.mjs";
import { parseReports } from "../Presentation/parse.mjs";
import { compileSlides } from "../Presentation/template.mjs";
import { loadReport } from "../../.github/extensions/waf-review-dashboard/lib/report.mjs";
import { reportFixture } from "./report-fixture.mjs";

async function dashboard(t, inputs) {
    const dir = await mkdtemp(path.join(tmpdir(), "azure-review-"));
    t.after(() => rm(dir, { recursive: true, force: true }));
    await Promise.all(Object.entries(inputs).map(([file, content]) => writeFile(path.join(dir, file), content)));
    return loadReport(dir);
}

test("197 controls survive report, dashboard and slide consumers with five mapped pillars", async t => {
    const inputs = reportFixture({ overrides: { "AZSQL-01": "Fail", "BLOB-05": "Fail" } });
    const parsed = parseReports(inputs), report = await dashboard(t, inputs);
    assert.equal(parsed.controls.length, 197);
    assert.equal(report.controls.length, 197);
    assert.equal(report.controls.filter(control => control.id.startsWith("AZSQL-")).length, 20);
    assert.equal(report.controls.filter(control => control.id.startsWith("BLOB-")).length, 20);
    assert.deepEqual(parsed.pillars.map(pillar => pillar.total), [34, 52, 24, 32, 30]);
    assert.equal(new Set(parsed.pillars.flatMap(pillar => pillar.controlIds)).size, 172);
    assert.equal(parsed.pillars[0].score, 97);
    assert.equal(parsed.pillars[1].score, 98);
    assert.equal(parsed.overall.score, 99);
    assert.deepEqual([report.posture.score, report.posture.coverage], [parsed.overall.score, parsed.overall.coverage]);
    const slides = compileSlides(parsed);
    assert.equal(slides.filter(slide => slide.kind === "pillar").length, 5);
    assert.match(JSON.stringify(slides.find(slide => slide.kind === "pillar" && slide.title === "Reliability")), /AZSQL-01/);
    assert.match(JSON.stringify(slides.find(slide => slide.kind === "pillar" && slide.title === "Security")), /BLOB-05/);
    assert.doesNotMatch(JSON.stringify(slides), /wordpress|six pillars/i);
});

test("SQL and Blob only scopes contribute to every pillar without governance inflating the headline", async t => {
    const overrides = Object.fromEntries(CONTROLS.filter(control => /^(AZSQL|BLOB)-/.test(control.id)).map(control => [control.id, "Pass"]));
    overrides["AZSQL-01"] = "Fail";
    const inputs = reportFixture({ defaultStatus: "N/A", overrides });
    const parsed = parseReports(inputs), report = await dashboard(t, inputs);
    assert.equal(parsed.overall.score, 98);
    assert.equal(parsed.overall.coverage, 100);
    assert.equal(report.posture.score, 98);
    assert.equal(parsed.total.na, 157);
});

test("undefined headline measures agree across consumers", async t => {
    for (const defaultStatus of ["N/A", "Not verified"]) {
        const inputs = reportFixture({ defaultStatus });
        const parsed = parseReports(inputs), report = await dashboard(t, inputs);
        assert.equal(parsed.overall.score, null);
        assert.equal(report.posture.score, null);
        assert.equal(report.posture.coverage, defaultStatus === "N/A" ? null : 0);
    }
});

test("historical 157-control reports retain six-section scoring without being rewritten", async t => {
    const inputs = reportFixture({ legacy: true, overrides: { "APP-01": "Fail" } });
    const parsed = parseReports(inputs), report = await dashboard(t, inputs);
    assert.equal(parsed.controls.length, 157);
    assert.equal(parsed.overall.score, 100);
    assert.equal(report.posture.score, 100);
    assert.equal(report.pillars.length, 6);
    assert.match(report.warnings.join(" "), /Historical sections-v1/);
    assert.equal(compileSlides(parsed).find(slide => slide.kind === "scorecard").title, "Historical section scores");
});

test("current register rejects missing, duplicate and unknown IDs and unknown models", () => {
    const controls = CONTROLS.map(control => ({ ...control, status: "Pass" }));
    assert.throws(() => validateRegister(controls.slice(1), CHECKLIST.scoringModel), /Missing checklist/);
    assert.throws(() => validateRegister([...controls, controls[0]], CHECKLIST.scoringModel), /Duplicate/);
    assert.throws(() => validateRegister([{ id: "OTHER-01", status: "Pass" }], "sections-v1"), /Unknown control/);
    assert.throws(() => validateRegister(controls, "future-model"), /Unsupported scoring/);
    const scores = pillarScores(controls, CHECKLIST.scoringModel);
    assert.deepEqual(headlineScores(scores), { score: 100, coverage: 100 });
});

test("both report consumers reject a dropped SQL row or mismatched model provenance", async t => {
    const inputs = reportFixture();
    inputs["detailed-well-architected-review.md"] = inputs["detailed-well-architected-review.md"].replace(/^\| AZSQL-01.*\n/m, "");
    assert.throws(() => parseReports(inputs), /Missing checklist/);
    await assert.rejects(dashboard(t, inputs), /Missing checklist/);
    const mismatch = reportFixture();
    mismatch["executive-summary.md"] = mismatch["executive-summary.md"].replace("five-pillars-v2", "sections-v1");
    assert.throws(() => parseReports(mismatch), /identity mismatch/);
    await assert.rejects(dashboard(t, mismatch), /identity mismatch/);
});
