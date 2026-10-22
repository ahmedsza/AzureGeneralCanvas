# Scoring rubric

Deterministic rules so two runs against the same evidence produce the same numbers.

## Section score

Two numbers, always published together. Reporting either one alone is misleading.

```
Decided   = Total − N/A − Not verified
Score %    = Pass / Decided × 100          // of what evidence could decide, how much passed
Coverage % = Decided / (Total − N/A) × 100 // how much of the applicable checklist the evidence decided
```

`Not verified` is excluded from the score denominator so the score measures the configuration, not the collector's reach. Coverage carries the honesty: a 95% score at 40% coverage is a weak result and must be presented as such.

Round both to a whole number. If `Decided` is 0 but applicable controls exist, record the score as `n/a` and coverage as `0%`. If every control is `N/A`, both score and coverage are `n/a`.

Never state a score without its coverage figure alongside it — in the summary, the detailed report, on a slide, or in conversation with the user.

## RAG banding

| Band | Score % | Meaning |
|---|---|---|
| 🟢 Green | ≥ 90 | Meets the checklist; residual items are documented and accepted. |
| 🟡 Amber | 70–89 | Material gaps; remediation planned and owned. |
| 🔴 Red | < 70 | Gaps that put the stated SLO, data, or compliance position at risk. |

Two mandatory overrides:

- Any open severity-5 finding in the pillar forces 🔴 Red regardless of percentage.
- Coverage below 50% caps the band at 🟡 Amber — too little was proven to claim Green.

## Overall posture

Current reports use `five-pillars-v2`, defined in `Review/checklist.json`. Each control in Sections 2–7 maps to exactly one primary pillar (2=Reliability, 3=Security, 4=Cost, 5=Operations, 6=Performance). For groups with a `pillars` array, its first entry maps to suffix `01`, its second to `02`, and so on. Mixed concerns retain one primary pillar to avoid double-counting. Foundations/governance and the manual register have no pillar and remain separate audit areas.

Compute each pillar from its core controls plus its mapped service-specific controls, including Azure SQL and Blob Storage. The five-pillar rollup contains 172 distinct controls. Keep the eight-section audit summary and all 197 control rows unchanged in structure: section totals and pillar totals are different views, not additional control decisions. Do not add the two views together.

Overall score and coverage are unweighted means of the five pillar ratios, calculated from unrounded counts and rounded only once at the end. If any pillar's score is undefined, headline score is `n/a`; if any pillar's coverage is undefined, headline coverage is `n/a`. Never drop an undefined pillar or replace it with zero. Publish score and coverage independently. Severity-5 findings anywhere still force the overall risk band to Red.

Reports without an explicit scoring-model marker are historical `sections-v1` reports: preserve their six-section headline (foundations plus the five core sections), excluding the service and manual registers. Never relabel that as five-pillar scoring or rewrite historical decisions. Current reassessments must use the current revision, fingerprint and model.

## Finding scores

Every finding carries four independent 1–5 scores. 5 is always "high"; 1 is always "low".

**Severity** — how bad the exposure is if unaddressed:

| Score | Meaning |
|---|---|
| 5 | Direct exposure of data or admin control, or a single point of failure against a stated SLO. Example: origin reachable around the WAF, public MySQL access, no HA where RTO requires it. |
| 4 | Significant weakening of a control or recovery path. Example: backup retention below RPO, missing purge protection, shared-key storage access enabled. |
| 3 | Defence-in-depth gap with a compensating control present. Example: no diagnostic settings on a secondary resource. |
| 2 | Hygiene or cost/efficiency issue with no security or availability impact. |
| 1 | Cosmetic or advisory. |

**Effort** — remediation cost in engineering time and change risk. 1 = a portal or IaC toggle; 3 = a change requiring test and release; 5 = re-architecture, migration, or data movement.

**Risk** — risk *of the remediation itself* (change risk, potential for outage or regression). 1 = no user impact; 5 = requires downtime, data migration, or a cutover.

**Cost** — recurring Azure spend implied by remediating. 1 = no change or a saving; 3 = a modest tier or feature uplift; 5 = a significant SKU or redundancy uplift.

State the four scores plainly. Do not multiply them into a composite index — the four dimensions are for prioritisation conversations, and a single blended number hides the tradeoff.

## Prioritisation

Rank remediation as:

1. **Do now** — severity 4–5 with effort ≤ 2.
2. **Plan** — severity 4–5 with effort ≥ 3.
3. **Schedule** — severity 3.
4. **Backlog** — severity 1–2.

## Which findings reach the CSV

- Every `Fail`.
- Every `Not verified` where the underlying control is severity 4–5 if it turned out to be failing (for example untested restore, unverified origin bypass). Set `Status` to `Not verified` and make the recommendation the verification action, not a fix.
- Not every `Not verified` process control — summarise those as a single coverage row per pillar so the CSV stays actionable.

## Which findings reach the executive summary

- All severity-5 and severity-4 findings.
- The three to five strongest `Pass` results, chosen for business relevance, not count.
- The collection gaps that most limited confidence.

Cap the executive summary's key-findings table at 15 rows. If more qualify, keep the highest severity and point to the detailed report for the remainder.
