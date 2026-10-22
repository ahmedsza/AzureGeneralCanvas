import { readFileSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const CHECKLIST = JSON.parse(readFileSync(new URL("./checklist.json", import.meta.url), "utf8"));
export const LEGACY_MODEL = "sections-v1";
export const CONTROLS = CHECKLIST.groups.flatMap(group => {
    if (group.pillars && group.pillars.length !== group.count) throw new Error(`Invalid pillar mapping: ${group.prefix}`);
    return Array.from({ length: group.count }, (_, index) => ({
        id: `${group.prefix}-${String(index + 1).padStart(2, "0")}`,
        section: group.section,
        pillar: group.pillars?.[index] ?? group.pillar ?? null,
    }));
});
const registry = new Map(CONTROLS.map(control => [control.id, control]));
export const SECTIONS = CHECKLIST.sections.map(section => ({
    ...section, total: CONTROLS.filter(control => control.section === section.n).length,
    pillar: section.n >= 2 && section.n <= 6,
}));
export const PILLARS = SECTIONS.filter(section => section.pillar);
export const controlMetadata = id => registry.get(String(id).toUpperCase());
const hash = value => createHash("sha256").update(value).digest("hex");
export const questionFingerprint = question => hash(JSON.stringify([question.id, question.control, question.evidence, question.avoid ?? ""]));

export async function loadChecklistIdentity(root) {
    const file = path.join(root, ".github", "skills", "azure-waf-review", "references", "AzureWellArchitectedChecklist.md");
    const markdown = (await readFile(file, "utf8")).replace(/\r\n/g, "\n");
    const ids = [...markdown.matchAll(/^\|\s*([A-Z]+-\d{2})\s*\|/gm)].map(match => match[1]);
    if (ids.length !== CONTROLS.length || new Set(ids).size !== ids.length || ids.some(id => !registry.has(id))) {
        throw new Error("Checklist Markdown and Review/checklist.json control IDs disagree.");
    }
    if (!markdown.includes(`**${CHECKLIST.revision}**`)) throw new Error("Checklist revision and manifest disagree.");
    return {
        id: CHECKLIST.id, revision: CHECKLIST.revision, scoringModel: CHECKLIST.scoringModel,
        fingerprint: hash(JSON.stringify(CHECKLIST) + "\n" + markdown),
    };
}

export function reportIdentity(markdown) {
    const fields = {};
    for (const match of markdown.matchAll(/^\|\s*(Checklist ID|Checklist revision|Checklist fingerprint|Scoring model)\s*\|\s*([^|]+)\s*\|/gmi)) {
        const key = match[1].toLowerCase();
        if (Object.hasOwn(fields, key)) throw new Error(`Duplicate report identity field: ${key}`);
        fields[key] = match[2].replace(/[*`]/g, "").trim();
    }
    return {
        id: fields["checklist id"], revision: fields["checklist revision"],
        fingerprint: fields["checklist fingerprint"], scoringModel: fields["scoring model"] || LEGACY_MODEL,
    };
}

export function sameChecklist(left, right) {
    return Boolean(left?.fingerprint && right?.fingerprint &&
        ["id", "revision", "scoringModel", "fingerprint"].every(key => left[key] === right[key]));
}

export function validateRegister(controls, model) {
    if (![LEGACY_MODEL, CHECKLIST.scoringModel].includes(model)) throw new Error(`Unsupported scoring model: ${model}`);
    const ids = controls.map(control => control.id);
    if (new Set(ids).size !== ids.length) throw new Error("Duplicate control IDs in report.");
    for (const control of controls) {
        if (!registry.has(control.id)) throw new Error(`Unknown control ID ${control.id}`);
        if (!["Pass", "Fail", "N/A", "Not verified"].includes(control.status)) throw new Error(`Invalid status for ${control.id}`);
    }
    if (model === CHECKLIST.scoringModel) {
        const missing = CONTROLS.filter(control => !ids.includes(control.id));
        if (missing.length) throw new Error(`Missing checklist controls: ${missing.map(control => control.id).join(", ")}`);
    }
}

export function tally(controls) {
    const [pass, fail, na, nv] = ["Pass", "Fail", "N/A", "Not verified"]
        .map(status => controls.filter(control => control.status === status).length);
    const total = controls.length, decided = pass + fail, applicable = total - na;
    return { total, pass, fail, na, nv,
        score: decided ? Math.round(pass / decided * 100) : null,
        coverage: applicable ? Math.round(decided / applicable * 100) : null };
}

export function pillarScores(controls, model) {
    const groups = model === LEGACY_MODEL ? SECTIONS.slice(0, 6) : PILLARS;
    return groups.map(section => {
        const members = controls.filter(control => {
            const meta = controlMetadata(control.id);
            return (model === LEGACY_MODEL ? meta?.section : meta?.pillar) === section.n;
        });
        return { ...section, ...tally(members), controlIds: members.map(control => control.id) };
    });
}

export function headlineScores(scores) {
    return Object.fromEntries(["score", "coverage"].map(key => {
        const values = scores.map(score => {
            const decided = score.pass + score.fail;
            const denominator = key === "score" ? decided : score.total - score.na;
            return denominator ? (key === "score" ? score.pass : decided) / denominator * 100 : null;
        });
        return [key, !values.length || values.includes(null) ? null : Math.round(values.reduce((a, b) => a + b, 0) / values.length)];
    }));
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
    if (process.argv[2] !== "--identity") throw new Error("Usage: node Review\\checklist.mjs --identity");
    console.log(JSON.stringify(await loadChecklistIdentity(path.resolve(import.meta.dirname, "..")), null, 2));
}
