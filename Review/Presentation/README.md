# Azure review presentation generator

Builds an optional deck from existing `executive-summary.md`, `detailed-well-architected-review.md`
and `findings.csv`. It does not collect Azure evidence or reassess control decisions.

```powershell
npm ci --prefix .\Review\Presentation
node .\Review\Presentation\generate.mjs --report-dir "<report-directory>" --mode executive
```

Install dependencies only when missing. Use `--mode detailed` for the high-impact findings
appendix, and `--render-changed` for optional desktop PowerPoint rendering on Windows.
Ordinary generation needs Node.js and the pinned dependencies, not desktop PowerPoint.

Current reports require all 197 controls, matching checklist identity tables and five-pillar
rollups. `Review\checklist.json` maps each core/service control to one primary pillar; governance
and the manual register remain separate. Historical reports without a model marker retain their
six-section scoring and assessed totals. Undefined measures remain `n/a`, never zero.

The cache includes report contents, mode, shared registry/scoring implementation, renderer and
dependency versions. The deck is published atomically only after validation; a failed build
does not replace an existing deck. Do not edit saved reports just to satisfy the renderer.
