import { CHECKLIST, CONTROLS, SECTIONS, LEGACY_MODEL, headlineScores, loadChecklistIdentity, pillarScores, tally } from "../checklist.mjs";
import path from "node:path";

export const identity = await loadChecklistIdentity(path.resolve(import.meta.dirname, "..", ".."));
export const identityRows = value => `| Field | Value |
|---|---|
| Checklist ID | ${value.id} |
| Checklist revision | ${value.revision} |
| Checklist fingerprint | ${value.fingerprint} |
| Scoring model | ${value.scoringModel} |`;
const scoreRow = (label, score) => {
    const band = score.score === null ? "Amber" : score.score < 70 ? "Red" :
        score.coverage !== null && score.coverage < 50 ? "Amber" : score.score >= 90 ? "Green" : "Amber";
    return `| ${label} | ${["total", "pass", "fail", "na", "nv", "score", "coverage"].map(key => score[key] ?? "n/a").join(" | ")} | ${band} |`;
};
const header = "| Section | Total | Pass | Fail | N/A | Not verified | Score % | Coverage % | Status |\n|---|---|---|---|---|---|---|---|---|\n";

export function reportFixture({ overrides = {}, defaultStatus = "Pass", legacy = false } = {}) {
    const model = legacy ? LEGACY_MODEL : CHECKLIST.scoringModel;
    const controls = CONTROLS.filter(control => !legacy || !/^(AZSQL|BLOB)-/.test(control.id))
        .map(control => ({ ...control, status: overrides[control.id] ?? defaultStatus }));
    const sections = SECTIONS.map(section => ({ ...section, ...tally(controls.filter(control => control.section === section.n)) }));
    const pillars = pillarScores(controls, model), total = tally(controls), overall = headlineScores(pillars);
    const audit = header + sections.map(section => scoreRow(`${section.n}. ${section.label}`, section)).join("\n") + "\n" + scoreRow("Total", total);
    const rollup = header.replace("Section | Total", "Pillar | Controls") + pillars.map(pillar => scoreRow(pillar.label, pillar)).join("\n");
    const provenance = legacy ? "" : identityRows(identity);
    const register = SECTIONS.map(section => {
        const manual = section.n === 8;
        const heading = manual ? "| ID | Manual validation | Evidence | Status | Owner | Date |" : "| ID | Control | Status | Evidence | Observation | Recommendation |";
        return heading + "\n|---|---|---|---|---|---|\n" + controls.filter(control => control.section === section.n).map(control =>
            manual ? `| ${control.id} | Manual check | Fixture reference | ${control.status} | Owner | 2026-10-21 |` :
                `| ${control.id} | Synthetic control | ${control.status} | Fixture reference | Synthetic observation | Review configuration |`).join("\n");
    }).join("\n\n");
    return {
        "executive-summary.md": `# Synthetic review\n${provenance}\n\n## Overall posture
| Measure | Result |
|---|---|
| Overall score | ${overall.score === null ? "n/a" : overall.score + "%"} |
| Evidence coverage | ${overall.coverage === null ? "n/a" : overall.coverage + "%"} |
| Controls assessed | ${total.total} of ${total.total} |
| Pass / Fail / N/A / Not verified | ${total.pass} / ${total.fail} / ${total.na} / ${total.nv} |

## Pillar scorecard
${legacy ? audit : rollup + "\n\n## Section audit totals\n" + audit}`,
        "detailed-well-architected-review.md": `# Synthetic review\n## 1. Scope and method\n${provenance}\n\n## 2. Scoring summary\n${audit}\n\n${legacy ? "" : "### Pillar rollup\n" + rollup + "\n\n"}## 3. Controls\n${register}`,
        "findings.csv": "FindingId,ControlId,Pillar,Resource,Title,Summary,Status,Severity,Effort,Risk,Cost,Priority,Evidence,Recommendation\n" +
            controls.filter(control => control.status === "Fail").map((control, index) =>
                `F-${index + 1},${control.id},${SECTIONS.find(section => section.n === control.pillar)?.label ?? "Governance"},Fixture,Example finding,Example observation,Fail,4,2,2,2,Do now,Fixture reference,Review configuration`).join("\n"),
    };
}
