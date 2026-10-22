# Azure Resource Group Review Toolkit

This folder collects redacted configuration evidence from an Azure resource group, then uses that evidence to drive a manual or Copilot-assisted Azure Well-Architected review across all five pillars.

The collection layer is workload-independent: it accepts any resource group, inventories every resource in it, and dispatches supported resource types to dedicated collectors. Supported services include App Service Plan, App Service and slots, Azure SQL logical servers/databases/elastic pools, MySQL Flexible Server, Key Vault, Redis, NAT Gateway, Azure Front Door/WAF, Storage accounts and Blob Storage, Azure Communication Services, Application Insights, Log Analytics, and supporting network resources. The updated `AzureWellArchitectedChecklist.md` is application-neutral and includes Azure SQL Database and Blob Storage supplements across all five pillars.

Collectors are PowerShell scripts that invoke Azure CLI (`az`) through the shared `Invoke-AzCommandJson` helper and write JSON evidence. New collectors should follow this pattern rather than use Azure PowerShell (`Az.*`) modules or Azure SDKs.

## Contents

```
PSScripts/
  Invoke-CollectData.ps1              # Workload-independent collection entry point
  Common-AzureCollector.ps1            # Shared helpers (az CLI wrapper, redaction, document/manifest helpers)
  Test-WafReviewPrerequisites.ps1      # Workflow helper: validates local prerequisites
  Get-WafReviewAzureScope.ps1          # Workflow helper: lists subscriptions and resource groups
  Get-WafReviewResourceInventory.ps1   # Workflow helper: pre-assessment resource inventory
  Get-*.ps1                            # One collector per resource type, invoked automatically by the entry point
```

The canonical checklist, evidence map, scoring rubric, report templates, and presentation template now live with the project skill under [.github/skills/azure-waf-review/references/](../.github/skills/azure-waf-review/references/).

The legacy entry point remains a forwarding wrapper for external callers. New workflows use
`Invoke-CollectData.ps1` directly. `checklist.json` is the shared control/pillar registry;
`node .\Review\checklist.mjs --identity` (from the project root) reports the current revision and
fingerprint. Current reports include service controls in five-pillar scoring, with governance
and the manual register separate. Historical report decisions are not silently migrated.

## Prerequisites

- PowerShell 7 is required.
- Azure CLI must be installed and authenticated with `az login`.
- `Reader` is sufficient for much configuration evidence. Use `Monitoring Reader`, `Security Reader`, and permissions to read Key Vault object metadata when the environment permits it.
- The new SQL and Blob collectors use management-plane configuration reads. They do not query SQL tables, read blob contents, fetch storage account keys, or require SQL credentials or Storage Blob Data Reader access.

## Run

From the `Review` folder:

```powershell
.\PSScripts\Invoke-CollectData.ps1 -ResourceGroup <resource-group-name> -OutputDirectory <output-directory>
```

Use a specific subscription or output directory when required:

```powershell
.\PSScripts\Invoke-CollectData.ps1 `
  -ResourceGroup <resource-group-name> `
  -Subscription <subscription-id> `
  -OutputDirectory C:\Reports\azure-data
```

## Output

Each resource has its own JSON document. A section records the Azure CLI command, success state, exit code, error, and returned payload. `collection-manifest.json` indexes output files and identifies resources that were inventoried but have no dedicated collector. `resource-group-inventory.json` contains the complete RG inventory, its locks, and resource-group role assignments.

After collection and manifest creation complete, the collector compresses the output directory into a uniquely named ZIP archive beside that directory. The default directory is `azure-data-yyyyMMdd-HHmmss`. The archive name uses the output directory name, a UTC timestamp, and a GUID fragment.

The returned object includes `outputDirectory`, `manifest`, `zipFile`, and `discoveredResources`. Capture it to retrieve the archive path:

```powershell
$result = .\PSScripts\Invoke-CollectData.ps1 -ResourceGroup <resource-group-name>
$result.zipFile
```

Sensitive property names and values, including passwords, connection strings, account keys, SAS values, and instrumentation keys, are replaced with `SECRET_FOUND_REDACTED`. The collection intentionally lists Key Vault secret metadata but never reads secret values.

### SQL and Blob collection

| Files | Configuration collected |
|---|---|
| `azure-sql-server-<server>.json` | Server configuration, firewall/VNet rules, Entra administrators and Entra-only authentication, auditing, TDE protector, failover groups, database and elastic pool inventory |
| `azure-sql-database-<server>-<database>.json` | Database SKU/capacity, availability/backup configuration, TDE, auditing, short- and long-term retention policies, replication links |
| `azure-sql-elastic-pool-<server>-<pool>.json` | Pool SKU/capacity and availability configuration |
| `storage-<account>.json` | Existing storage account evidence, network rules, Blob service properties, lifecycle management policy |
| `blob-storage-<account>.json` | Blob service properties (including retention/versioning), container management metadata (including public access, immutability and legal-hold indicators), object replication policies |

The SQL server collector returns discovered databases and pools to the entry point for individual collection, even if Azure's resource-group list omitted them. Storage accounts similarly schedule Blob service collection, except for file-only accounts. Child resource IDs are deduplicated case-insensitively, and each resulting evidence file is indexed in the manifest. Diagnostic settings, locks, and role assignments are collected for SQL resources and the Blob service when its ID is available.

The resource-group inventory and `discovery.totalResourcesInGroup` retain the original `az resource list` result. Additional children are recorded in their parent output's `discoveredResources` field and in `discovered-resource-ids.json`. To support another service, add its resource type to `Get-ResourceCollectorScriptName` in `Common-AzureCollector.ps1` and implement the standard collector parameters/output contract.

## Assessment Evidence

Security evidence includes public/private network exposure, App Service access restrictions and authentication, managed identities, RBAC, Key Vault access and networking, TLS settings, storage public access and shared-key configuration, Front Door custom domains and WAF policies, MySQL firewall/private access, diagnostic settings, and Defender for Cloud plans and recommendations.

Reliability evidence includes App Service Plan SKU and application placement, slots, App Service configuration and VNet integration, MySQL high availability/backup configuration, Redis configuration, Storage retention/lifecycle configuration, NAT Gateway subnet association, Front Door routing/origins, and Application Insights/Log Analytics availability telemetry.

The evidence model follows the Microsoft cloud security benchmark's feature-driven Azure baselines: network security, logging and threat detection, identity and access management, data protection, secure configuration, and data recovery. Refer to the [Azure security baselines overview](https://learn.microsoft.com/en-us/security/benchmark/azure/security-baselines-overview) during assessment interpretation.

## Limits

The collector preserves failed optional calls as evidence because Azure CLI extensions, resource-provider API versions, and the caller's RBAC permissions vary. Azure CLI output is point-in-time configuration evidence; it does not replace live availability testing, application vulnerability scanning, backup restore testing, WAF attack simulation, or an Azure Policy compliance review.

Azure SQL support currently covers logical servers, databases, and elastic pools, not SQL Managed Instance or SQL Server on VMs. Other unrecognized resource types remain in the inventory and `unsupportedResources`; they are not silently treated as supported. Collection is configuration evidence, not proof of every checklist control; restore tests, SQL grants/query tuning, Blob content/inventory, costs and operational processes require separate evidence.

Inspect `collection-manifest.json` for unexpected entries under `errors` or `unsupportedResources`, and inspect each document for failed optional sections. Offline regression tests mock Azure CLI and require Pester 5:

```powershell
Invoke-Pester -Path .\PSScripts\tests\Collection.Tests.ps1 -Output Detailed
```

## Generate a report from the evidence

Once a collection run completes, use the existing review skill in VS Code Chat to turn the collector JSON and the bundled [AzureWellArchitectedChecklist.md](../.github/skills/azure-waf-review/references/AzureWellArchitectedChecklist.md) into a scored Well-Architected review:

```
/azure-waf-review <path-to-collector-output-directory>
```

Give it a resource group instead of a directory and it runs the collector first. By default it writes three reports to `Review/reports/<evidence-folder-name>-reports/`. PowerPoint is optional:

| File | Purpose |
|---|---|
| `executive-summary.md` | Pillar scorecard, key findings (good and bad), prioritised remediation |
| `detailed-well-architected-review.md` | All 197 checklist controls with status, evidence pointer, and recommendation |
| `findings.csv` | One row per finding, scored 1-5 for severity, effort, change risk, and cost |
| `well-architected-review.pptx` (optional) | Executive (10–15 slides) or detailed readout from the finished reports |

The dashboard is ready after the three reports. To build a deck separately, select optional Step 9
in the workflow or use the [reusable generator](Presentation/README.md):

```powershell
# From the repository root; install dependencies only once:
npm ci --prefix .\Review\Presentation
node .\Review\Presentation\generate.mjs --report-dir ".\Review\reports\<evidence-folder-name>-reports" --mode executive
```

Use `--mode detailed` to expand findings, and `--render-changed` for optional changed-slide
inspection in Windows PowerPoint. Plain generation requires only Node.js and local dependencies.
Cached builds reuse unchanged results; a failed build never prevents viewing the existing reports.

A control is marked `Pass` or `Fail` only where collected evidence proves the outcome; anything the collector cannot decide is reported as `Not verified` and reflected in a separate coverage figure. Skill definition: [.github/skills/azure-waf-review/SKILL.md](../.github/skills/azure-waf-review/SKILL.md).
