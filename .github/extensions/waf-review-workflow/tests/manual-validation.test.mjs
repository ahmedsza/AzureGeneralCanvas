import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readFile, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { loadQuestions, loadManual, manualPath, parseQuestions, saveManualAnswer, validateAnswer, writeManualSnapshot, staleAnswerIds } from "../manual-validation.mjs";

const root = path.resolve(import.meta.dirname, "..", "..", "..", "..");
const questions = await loadQuestions(root);
const answer = { controlId: "MAN-01", decision: "met", response: "Business targets approved", evidence: "BIA v2", respondent: "Owner", evidenceDate: "2026-09-28" };
async function fixture(t) {
    const root = await mkdtemp(path.join(tmpdir(), "waf-manual-"));
    t.after(() => rm(root, { recursive: true, force: true }));
    return root;
}
test("all 197 checklist questions are available, including SQL, Blob and application-neutral controls", () => {
    assert.equal(questions.length, 197);
    assert.equal(questions.filter(q => q.id.startsWith("MAN-")).length, 12);
    assert.equal(questions.filter(q => q.id.startsWith("AZSQL-")).length, 20);
    assert.equal(questions.filter(q => q.id.startsWith("BLOB-")).length, 20);
    assert.match(questions.find(q => q.id === "SQL-01").control, /MySQL/);
    for (const id of ["FND-01", "FND-06", "CST-14", "OPS-16", "PRF-06", "SEC-20", "MAN-12"]) {
        assert.equal(questions.find(q => q.id === id).suggested, true, id);
    }
    assert.ok(questions.every(q => q.question && q.evidence && q.section));
});
test("checklist section totals and new five-pillar service groups match the published summary", async () => {
    const checklist = await readFile(path.join(root, ".github", "skills", "azure-waf-review", "references", "AzureWellArchitectedChecklist.md"), "utf8");
    assert.doesNotMatch(checklist, /wordpress|wp-config|wp-admin|wp-cron|WP_DEBUG|DISALLOW_FILE_EDIT|phpMyAdmin|OPcache/i);
    assert.match(checklist, /2026-10-21-r3/);
    const expected = [13, 17, 24, 14, 17, 15, 85, 12];
    for (const [index, total] of expected.entries()) {
        assert.equal(questions.filter(q => q.section.startsWith(`${index + 1}.`)).length, total);
        assert.match(checklist, new RegExp(`\\| ${index + 1}\\. [^|]+\\| ${total} \\|`));
    }
    assert.match(checklist, /\|\s*\*\*TOTAL\*\*\s*\|\s*\*\*197\*\*/);
    for (const [number, prefix, service] of [["11", "AZSQL", "Azure SQL Database"], ["12", "BLOB", "Azure Blob Storage"]]) {
        const supplement = checklist.split(`### 7.${number} ${service}`)[1].split(/### 7\.|## 8\./)[0];
        const groups = supplement.split(/^#### /m).slice(1);
        assert.equal(groups.length, 5);
        for (const [index, name] of ["Reliability", "Security", "Cost Optimization", "Operational Excellence", "Performance Efficiency"].entries()) {
            assert.ok(groups[index].startsWith(name));
            assert.equal([...groups[index].matchAll(new RegExp(`^\\| ${prefix}-\\d{2} \\|`, "gm"))].length, [4, 6, 3, 3, 4][index]);
        }
        assert.match(supplement, new RegExp(`https://learn.microsoft.com/en-us/azure/well-architected/service-guides/${prefix === "AZSQL" ? "azure-sql-database" : "azure-blob-storage"}`));
    }
});
test("new manual-only SQL and Blob controls remain suggested for supporting evidence", () => {
    for (const id of ["AZSQL-04", "AZSQL-09", "AZSQL-14", "AZSQL-18", "AZSQL-20", "BLOB-04", "BLOB-14", "BLOB-19", "BLOB-20"]) {
        assert.equal(questions.find(q => q.id === id).reason, "Collector cannot establish this control", id);
    }
});
test("Not verified report rows become questions even for collector-assisted controls", async () => {
    const checklist = await readFile(path.join(root, ".github", "skills", "azure-waf-review", "references", "AzureWellArchitectedChecklist.md"), "utf8");
    const mapping = await readFile(path.join(root, ".github", "skills", "azure-waf-review", "references", "evidence-map.md"), "utf8");
    const parsed = parseQuestions(checklist, mapping, "| SEC-06 | TLS | Not verified | Missing property |\n| FND-01 | Ownership | Pass | dated evidence |");
    assert.equal(parsed.find(q => q.id === "SEC-06").reason, "Not verified in the current report");
    assert.equal(parsed.find(q => q.id === "SEC-06").suggested, true);
    assert.equal(parsed.find(q => q.id === "FND-01").suggested, false);
});
test("answers and edit history persist; concurrent stale writes cannot overwrite", async t => {
    const root = await fixture(t);
    const first = await saveManualAnswer(root, "run-a", 0, answer, questions);
    assert.equal(first.revision, 1);
    await assert.rejects(saveManualAnswer(root, "run-a", 0, { ...answer, response: "stale" }, questions), /changed in another panel/);
    const second = await saveManualAnswer(root, "run-a", 1, { ...answer, response: "Revised" }, questions);
    assert.equal(second.history.length, 2);
    assert.equal((await loadManual(root, "run-a")).responses["MAN-01"].response, "Revised");
    assert.deepEqual((await loadManual(root, "run-b")).responses, {});
});
test("snapshots are immutable and skipped snapshots contain no responses", async t => {
    const root = await fixture(t);
    const first = await saveManualAnswer(root, "run-a", 0, answer, questions);
    const snapshot = await writeManualSnapshot(root, "run-a", first, questions);
    await saveManualAnswer(root, "run-a", 1, { ...answer, response: "changed" }, questions);
    const published = JSON.parse(await readFile(snapshot.file, "utf8"));
    assert.equal(published.responses[0].response, answer.response);
    assert.equal(published.unansweredControlIds.length, questions.length - 1);
    const skipped = await writeManualSnapshot(root, "run-a", first, questions, true);
    assert.equal(JSON.parse(await readFile(skipped.file, "utf8")).responses.length, 0);
});
test("invalid input and corrupted persistence produce explicit errors", async t => {
    const root = await fixture(t);
    assert.throws(() => manualPath(root, "..\\escape"), /Invalid/);
    assert.throws(() => validateAnswer({ ...answer, controlId: "NO-99" }, questions), /valid checklist/);
    assert.throws(() => validateAnswer({ ...answer, evidenceDate: "2026-02-30" }, questions), /real date/);
    assert.throws(() => validateAnswer({ ...answer, respondent: "" }, questions), /name and an explanation/);
    await saveManualAnswer(root, "run-a", 0, answer, questions);
    await writeFile(manualPath(root, "run-a"), "");
    await assert.rejects(loadManual(root, "run-a"), SyntaxError);
});
test("unknown and incomplete evidence can be saved without inventing verification", () => {
    const saved = validateAnswer({ ...answer, decision: "unknown", respondent: "", response: "", evidenceDate: "", evidence: "" }, questions);
    assert.equal(saved.decision, "unknown");
    assert.equal(Object.hasOwn(saved, "status"), false);
});

test("changed or unversioned questions require reconfirmation, retaining earlier evidence and history", async t => {
    const root = await fixture(t);
    const saved = await saveManualAnswer(root, "changed", 0, answer, questions);
    const updated = questions.map(q => q.id === answer.controlId ? { ...q, control: "Changed recovery requirement" } : q);
    assert.deepEqual(staleAnswerIds(saved, updated), [answer.controlId]);
    await assert.rejects(writeManualSnapshot(root, "changed", saved, updated), /Reconfirm/);
    const skipped = await writeManualSnapshot(root, "changed", saved, updated, true);
    assert.deepEqual(JSON.parse(await readFile(skipped.file, "utf8")).responses, []);
    await assert.rejects(saveManualAnswer(root, "changed", 1, { ...answer, controlFingerprint: saved.responses[answer.controlId].controlFingerprint }, updated), /changed while you were editing/);
    const confirmed = await saveManualAnswer(root, "changed", 1, answer, updated);
    assert.deepEqual(staleAnswerIds(confirmed, updated), []);
    assert.notEqual(confirmed.history[0].control, confirmed.history[1].control);
    const snapshot = await writeManualSnapshot(root, "changed", confirmed, updated);
    const data = JSON.parse(await readFile(snapshot.file, "utf8"));
    assert.equal(data.responses[0].control, "Changed recovery requirement");
    assert.equal(data.checklist.revision, questions[0].checklist.revision);
    const legacy = { ...saved, responses: { [answer.controlId]: answer } };
    assert.deepEqual(staleAnswerIds(legacy, questions), [answer.controlId]);
    await assert.rejects(writeManualSnapshot(root, "changed", legacy, questions), /Reconfirm/);
});
