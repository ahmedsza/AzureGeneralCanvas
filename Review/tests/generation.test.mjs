import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { generate } from "../Presentation/generate.mjs";
import { reportFixture } from "./report-fixture.mjs";

test("current and historical decks build, validate and reuse cache", async t => {
    for (const legacy of [false, true]) {
        const reportDir = await mkdtemp(path.join(tmpdir(), "azure-review-deck-"));
        t.after(() => rm(reportDir, { recursive: true, force: true }));
        const inputs = reportFixture({ legacy, overrides: legacy ? { "APP-01": "Fail" } : { "AZSQL-01": "Fail", "BLOB-05": "Fail" } });
        await Promise.all(Object.entries(inputs).map(([name, text]) => writeFile(path.join(reportDir, name), text)));
        const built = await generate({ reportDir, mode: "executive" });
        assert.equal(built.ok, true);
        assert.equal(built.slideCount, legacy ? 15 : 14);
        assert.equal(built.cached, false);
        assert.equal((await generate({ reportDir, mode: "executive" })).cached, true);
        assert.equal((await generate({ reportDir, mode: "detailed" })).slideCount, legacy ? 16 : 15);
    }
});
