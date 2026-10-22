# Collector evidence map

How `Invoke-CollectData.ps1` (schema `4.0`) lays out its output, and which checklist controls each file informs. The previous entry point remains a compatibility wrapper.

## Document shape

Every resource file has the same shape:

```jsonc
{
  "metadata": { "schemaVersion": "4.0", "generatedAtUtc": "...", "resourceType": "...",
                "resourceName": "...", "resourceGroup": "...", "subscription": "..." },
  "sections": {
    "<sectionName>": {
      "success": true,          // false => the az call failed; status is "Not verified"
      "command": "az ...",      // reproduce or cite this in the report
      "exitCode": 0,
      "error": null,            // populate the collection-gaps appendix from this
      "data": { }               // redacted payload
    }
  }
}
```

Cite evidence as `<file> → sections.<section>.data.<path> = <value>`.

## Index files

| File | Use for |
|---|---|
| `collection-manifest.json` | `discovery.resourceTypes`, `outputs[]` (resource → file), `unsupportedResources[]`, `errors[]`. Read first. |
| `resource-group-inventory.json` | `sections.resourceGroup`, `sections.resources`, `sections.locks` (FND-11), `sections.roleAssignments` (FND-07, FND-08). |
| `discovered-resource-ids.json` | Resource IDs used to scope Defender/Advisor findings to this workload. |
| `defender-for-cloud.json` | `sections.pricing` (SEC-21, DEF-02), `sections.contacts`, `sections.assessments` (DEF-01), `sections.recommendations` (FND-10). |

## Resource files

| File pattern | Sections | Primary controls |
|---|---|---|
| `appservice-plan-<name>.json` | `show`, `apps`, `diagnosticSettings`, `locks`, `roleAssignments` | REL-03, REL-06, CST-03, CST-11, PRF-03, APP-02 |
| `appservice-<name>.json` | `show`, `config`, `logging`, `appSettings`, `connectionStrings`, `auth`, `identity`, `accessRestrictions`, `vnetIntegration`, `hostnames`, `slots`, `diagnosticSettings`, `locks`, `roleAssignments` | REL-03, REL-04, REL-07, SEC-03, SEC-05, SEC-06, SEC-09, SEC-11, SEC-14, SEC-18, SEC-24, OPS-04, OPS-07, PRF-10, PRF-11 |
| `appservice-slot-<app>-<slot>.json` | `show`, `diagnosticSettings`, `locks`, `roleAssignments` | OPS-04, APP-01 |
| `mysql-flexible-server-<name>.json` | `show`, `databases`, `firewallRules`, `configurations`, `backups`, `diagnosticSettings`, `locks`, `roleAssignments` | REL-08, REL-09, SEC-04, SEC-12, SEC-16, CST-04, SQL-02, SQL-03, SQL-04, PRF-12 |
| `keyvault-<name>.json` | `show`, `diagnosticSettings`, `locks`, `roleAssignments` | SEC-14, SEC-15, KV-01 |
| `redis-<name>.json` | `show`, `redisShow` (classic only), `diagnosticSettings`, `locks`, `roleAssignments` | REL-05, SEC-12, RDS-01, RDS-02, RDS-03, PRF-09 |
| `frontdoor-<name>.json` | `show`, `endpoints`, `routes`, `diagnosticSettings`, `locks`, `roleAssignments` | REL-13, SEC-07, SEC-08, SEC-09, CST-08, FD-01, FD-02, FD-03, PRF-07, PRF-08 |
| `azure-sql-server-<server>.json` | `show`, `firewallRules`, `virtualNetworkRules`, `entraAdministrators`, `entraOnlyAuthentication`, `auditing`, `encryptionProtector`, `failoverGroups`, `databases`, `elasticPools`, `diagnosticSettings`, `locks`, `roleAssignments` | AZSQL-02, AZSQL-05, AZSQL-06, AZSQL-07, AZSQL-08, AZSQL-10, AZSQL-12, AZSQL-15 |
| `azure-sql-database-<server>-<database>.json` | `show`, `transparentDataEncryption`, `auditing`, `shortTermRetention`, `longTermRetention`, `replicationLinks`, `diagnosticSettings`, `locks`, `roleAssignments` | AZSQL-01, AZSQL-02, AZSQL-03, AZSQL-08, AZSQL-10, AZSQL-11, AZSQL-12, AZSQL-13, AZSQL-15, AZSQL-16, AZSQL-17, AZSQL-19 |
| `azure-sql-elastic-pool-<server>-<pool>.json` | `show`, `diagnosticSettings`, `locks`, `roleAssignments` | AZSQL-01, AZSQL-12, AZSQL-15, AZSQL-16, AZSQL-17 |
| `storage-<name>.json` | `show`, `networkRules`, `blobService`, `managementPolicy`, `diagnosticSettings`, `locks`, `roleAssignments` | REL-11, REL-12, SEC-16, SEC-17, CST-07, BLOB-01, BLOB-02, BLOB-05, BLOB-06, BLOB-07, BLOB-08, BLOB-09, BLOB-10, BLOB-11, BLOB-12, BLOB-13, BLOB-17, BLOB-18 |
| `blob-storage-<account>.json` | `show`, `containers`, `objectReplicationPolicies`, `diagnosticSettings`, `locks`, `roleAssignments` (last three only when service ID is available) | BLOB-02, BLOB-03, BLOB-05, BLOB-07, BLOB-09, BLOB-10, BLOB-12, BLOB-15, BLOB-16, BLOB-18 |
| `nat-gateway-<name>.json` | `show`, `subnetAssociations`, `diagnosticSettings`, `locks`, `roleAssignments` | SEC-11, NAT-01, NAT-02, NAT-03, NAT-05, NAT-06 |
| `network-<type>-<name>.json` | `show`, `diagnosticSettings`, `locks`, `roleAssignments` | SEC-11, SEC-12, SEC-13, NET-01, NET-03, NET-04, NET-06 |
| `app-insights-<name>.json` | `show`, `diagnosticSettings`, `locks`, `roleAssignments` | OPS-08, MON-01, MON-02, MON-07, CST-09 |
| `log-analytics-<name>.json` | `show`, `diagnosticSettings`, `locks`, `roleAssignments` | OPS-07, MON-02, MON-03, MON-06, CST-09 |
| `communication-services-<name>.json` | `show`, `diagnosticSettings`, `locks`, `roleAssignments` | OPS-17, ACS-01, ACS-02, ACS-03 |

Resource names are sanitised with `[^A-Za-z0-9._-] → -`, so a file name may not match the Azure resource name character for character. Resolve files through `collection-manifest.json → outputs[].outputFile`, not by guessing names.

SQL databases/pools and Blob services can be discovered through their parent collectors even if absent from the original `resource list`. Include manifest child outputs in applicability decisions, not just `discovery.resourceTypes`. A failed child-list call means child coverage is unknown. The `SQL-01`–`SQL-04` controls still refer to MySQL; Azure SQL Database uses `AZSQL-*`.

## High-value property paths

App Service (`appservice-<name>.json`):

| Property | Control |
|---|---|
| `sections.show.data.httpsOnly` | SEC-06 |
| `sections.config.data.minTlsVersion`, `.ftpsState`, `.remoteDebuggingEnabled` | SEC-05, SEC-06 |
| `sections.config.data.linuxFxVersion` | SEC-06, OPS-13 (configured Linux runtime/container; corroborate running version and lifecycle separately) |
| `sections.config.data.alwaysOn`, `.healthCheckPath`, `.autoHealEnabled` | REL-04 |
| `sections.config.data.numberOfWorkers`, `.clientAffinityEnabled` (on `show`) | REL-03 |
| `sections.show.data.publicNetworkAccess` | SEC-09 |
| `sections.show.data.identity.type` | SEC-03 |
| `sections.appSettings.data[]` — values shaped `@Microsoft.KeyVault(...)` | SEC-03, SEC-14 |
| `sections.appSettings.data[]` — runtime-specific settings and dependency/secret references | SEC-18, SEC-24 (settings alone do not prove effective hardening or environment/tenant isolation) |
| `sections.accessRestrictions.data.ipSecurityRestrictions`, `.scmIpSecurityRestrictions` | SEC-05, SEC-09 |
| `sections.auth.data.platform.enabled` | APP-01 |
| `sections.vnetIntegration.data[]` | SEC-11 |
| `sections.diagnosticSettings.data[]` | OPS-07, SEC-22 |

MySQL Flexible Server (`mysql-flexible-server-<name>.json`):

| Property | Control |
|---|---|
| `sections.show.data.highAvailability.mode`, `.standbyAvailabilityZone` | REL-08 |
| `sections.show.data.backup.backupRetentionDays`, `.geoRedundantBackup` | REL-08, REL-09 |
| `sections.show.data.network.publicNetworkAccess`, `.delegatedSubnetResourceId`, `.privateDnsZoneResourceId` | SEC-12 |
| `sections.show.data.sku.tier` | SQL-04, CST-04, PRF-03 |
| `sections.show.data.maintenanceWindow` | SQL-02 |
| `sections.show.data.storage.autoGrow`, `.iops`, `.storageSizeGB` | SQL-03 |
| `sections.firewallRules.data[]` — `0.0.0.0` or wide ranges | SEC-12, SEC-13 |
| `sections.configurations.data[]` — `require_secure_transport`, `sql_generate_invisible_primary_key`, `slow_query_log` | SEC-16, SQL-04, PRF-12 |

Storage (`storage-<name>.json`): `sections.show.data.allowBlobPublicAccess` (SEC-17), `.allowSharedKeyAccess` (SEC-17), `.minimumTlsVersion` (SEC-16), `.publicNetworkAccess` and `.networkRuleSet.defaultAction` (SEC-12), `.sku.name` (REL-11), `.accessTier` (CST-07).

### Azure SQL Database evidence

Check `success` before inspecting each section. These pointers identify configuration evidence, not automatic pass conditions; CLI/API versions can change payload nesting or omit unsupported properties. Cite the actual returned path. Missing fields do not prove disabled features.

| Document / path | Controls and evidence boundary |
|---|---|
| Server `sections.show.data.minimalTlsVersion`, `.publicNetworkAccess`; `sections.firewallRules.data`, `sections.virtualNetworkRules.data` | AZSQL-06, AZSQL-07. Database-scoped firewall rules, client certificate validation and effective network reachability require separate evidence. |
| Server `sections.entraAdministrators.data`, `sections.entraOnlyAuthentication.data`, `sections.show.data.identity`, `sections.roleAssignments.data` | AZSQL-05. Azure management roles and Entra configuration do not establish database users/roles or successful passwordless application authentication. |
| Database/pool `sections.show.data.sku`, `.zoneRedundant`; database `.elasticPoolId`, `.minCapacity`, `.autoPauseDelay`, `.currentBackupStorageRedundancy` where returned | AZSQL-01, AZSQL-03, AZSQL-11, AZSQL-12, AZSQL-13, AZSQL-17. SLO suitability, utilization, costs and actual scaling/resume behavior need additional evidence. |
| Server `sections.failoverGroups.data`; database `sections.replicationLinks.data` | AZSQL-02, AZSQL-19. Configuration does not prove replication lag, listener use, secondary capacity or successful failover. |
| Database `sections.shortTermRetention.data`, `sections.longTermRetention.data` | AZSQL-03, AZSQL-13. Retention settings do not prove restore success, actual backup consumption or immutability where not exposed. Use native SQL Database backup evidence, not SQL Server-on-VM backup assumptions. |
| Database `sections.transparentDataEncryption.data`; server `sections.encryptionProtector.data` | AZSQL-08. TDE/key type do not prove rotation, key recoverability or Always Encrypted/ledger configuration. |
| Server/database `sections.auditing.data`, resource `sections.diagnosticSettings.data` | AZSQL-10, AZSQL-15. Establish effective inherited policy and destinations; separately verify received events, retention, alerts and Defender coverage. |
| Database/pool `sections.show.data.maintenanceConfigurationId` where returned | AZSQL-16. The selected configuration does not prove application reconnect or maintenance/recovery rehearsal. |

### Blob Storage evidence

| Document / path | Controls and evidence boundary |
|---|---|
| Account `sections.show.data.kind`, `.isHnsEnabled`, `.sku.name`, `.primaryLocation`, `.secondaryLocation` | BLOB-01, BLOB-02, BLOB-17, BLOB-18. Validate feature compatibility; redundancy alone does not prove recovery or current replication health. |
| Account `sections.show.data.allowBlobPublicAccess`; Blob `sections.containers.data` | BLOB-05. Inspect each returned container's public-access value; static website exposure and anonymous access tests are separate evidence. |
| Account `sections.show.data.allowSharedKeyAccess`, `.sasPolicy`; account/service `sections.roleAssignments.data` | BLOB-06. These do not enumerate issued SAS, application credentials, container-scoped role assignments or HNS ACLs. User-delegation SAS is distinct from Shared Key-based SAS. |
| Account `sections.show.data.publicNetworkAccess`, `.networkRuleSet`; `sections.networkRules.data`; Blob `sections.show.data.cors` | BLOB-07. Private DNS, authorized/denied client paths and Blob/DFS endpoint behavior require tests. |
| Account `sections.show.data.enableHttpsTrafficOnly`, `.minimumTlsVersion`, `.encryption` | BLOB-08. Inspect actual CLI field names; detailed encryption-scope configuration and key recovery are not collected. |
| Blob `sections.show.data.deleteRetentionPolicy`, `.containerDeleteRetentionPolicy`, `.isVersioningEnabled`, `.restorePolicy`, `.changeFeed` | BLOB-03, BLOB-12. Retention/settings are not evidence of a successful restore or isolated/vaulted backup. |
| Blob `sections.containers.data` (public access, legal-hold and immutability indicators) | BLOB-05, BLOB-09, BLOB-16. Management metadata is not blob inventory/content, complete immutability-policy mode/duration or legal-hold approval. |
| Account `sections.show.data.allowCrossTenantReplication`; Blob `sections.objectReplicationPolicies.data` | BLOB-02, BLOB-10, BLOB-18. Policies do not prove replica health, matched object coverage, destination approvals or region-failover readiness. |
| Account `sections.show.data.accessTier`, `.isSftpEnabled`; `sections.managementPolicy.data` | BLOB-11, BLOB-12, BLOB-13. Account default tier and policy definitions do not prove individual object tiers, policy execution or savings. |
| Blob `sections.diagnosticSettings.data` | BLOB-10, BLOB-15. Use Blob service diagnostics, not account settings alone; logs received, alerts and Defender malware/other coverage need external evidence. |

Key Vault (`keyvault-<name>.json`): `sections.show.data.properties.enableRbacAuthorization` (SEC-15), `.enableSoftDelete`, `.enablePurgeProtection` (SEC-15), `.publicNetworkAccess`, `.networkAcls` (SEC-12), `.accessPolicies` (SEC-15).

Front Door (`frontdoor-<name>.json`): `sections.show.data.sku.name` (FD-01), `sections.routes.data[].cacheConfiguration` (PRF-07, PRF-08), `.forwardingProtocol`, `.originGroup` (SEC-09), `sections.show.data.properties.policySettings.mode` on WAF policy resources (SEC-07), `.managedRules`, `.customRules` (SEC-08, SEC-10).

Redis (`redis-<name>.json`): `sections.show.data.type` — `Microsoft.Cache/Redis` is the retiring classic service (RDS-01); `sections.redisShow.data.enableNonSslPort` (SEC-16), `.redisConfiguration.maxmemory-policy` (RDS-02), `.publicNetworkAccess` (SEC-12).

NAT Gateway (`nat-gateway-<name>.json`): `sections.show.data.sku.name` (NAT-02), `.publicIpAddresses`, `.publicIpPrefixes` (NAT-01, NAT-03), `sections.subnetAssociations.data[]` (NAT-01).

## Controls the collector cannot decide

These are always `Not verified` unless the user supplies external evidence: all of Section 8 (`MAN-01`–`MAN-12`); anything requiring a live test (SEC-23, REL-10, MAN-07, PRF-06); anything about process, ownership, or cost governance (FND-01 to FND-06, CST-01, CST-02, CST-06, CST-10 to CST-14, OPS-01, OPS-03, OPS-05, OPS-09 to OPS-16); application internals not exposed through app settings (SEC-19, SEC-20, PRF-10, PRF-11).

For the new supplements, AZSQL-04, AZSQL-09, AZSQL-14, AZSQL-18, AZSQL-20, BLOB-04, BLOB-14, BLOB-19 and BLOB-20 primarily require application, data-plane or operational evidence that the collectors do not capture. Every other new control can also require supporting evidence to decide its full design/test criteria, as noted above. A configuration match alone must not turn a compound control into a `Pass`.

SQL grants, Query Store, query plans, database-scoped settings/firewall rules, live metrics, backup restore results, detailed Defender coverage, cost exports, blob inventory, per-object tiers, issued SAS/ACLs, full immutability policies and vaulted backup jobs are not collected by the current scripts. Do not invent their values or describe these controls as script-verified. A proven failure can still decide a control despite other missing evidence.

Keep every control in its normal section table, and summarize evidence gaps under "Not verified — requires manual validation". Do not remove the full control audit trail or treat missing evidence as `N/A`.
