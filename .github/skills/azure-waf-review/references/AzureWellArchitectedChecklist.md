# Azure Resource Group — Well-Architected Checklist

This checklist assesses the workloads represented by an Azure resource group using the five Azure Well-Architected Framework pillars: Reliability, Security, Cost Optimization, Operational Excellence, and Performance Efficiency. A resource group is the collection boundary, not necessarily the complete workload boundary; record dependencies outside it and request their evidence when needed.

It covers App Service plans, web apps and slots, Azure SQL Database (logical servers, single databases and elastic pools), Azure Database for MySQL Flexible Server, Azure Front Door and WAF, Blob Storage, Key Vault, Azure Managed Redis or Azure Cache for Redis, virtual networking (VNet/NSG/private endpoints/private DNS/NAT Gateway), Azure Monitor (Application Insights/Log Analytics), Microsoft Defender for Cloud, and optional Azure Communication Services. SQL Managed Instance and SQL Server on VMs require separate service guidance; do not apply the Azure SQL Database supplement to them automatically.

Revision: **2026-10-21-r3**, **197 controls**. Controls assess Azure services and workload design without assuming an application product or runtime. Existing control IDs are retained, with application controls generalized to their security, reliability and operational intent; reassess earlier evidence against the current wording rather than carrying forward historical statuses. Azure SQL Database controls use `AZSQL-01`–`AZSQL-20`, and Blob Storage controls use `BLOB-01`–`BLOB-20`. Existing `SQL-01`–`SQL-04` IDs remain **MySQL** controls; never reinterpret them as Azure SQL Database controls.

## How to use this checklist

1. Record `Pass`, `Fail`, `N/A`, or `Not verified` for every applicable control. Do not use `N/A` without a documented rationale and approver.
2. A failed collection, unavailable API, or missing evidence means `Not verified`; it does not prove a control is absent.
3. Attach collector output (from `Review\PSScripts\Invoke-CollectData.ps1`), Azure Policy, Defender for Cloud, Azure Advisor, Azure Monitor, deployment code, tests, or operational records as evidence.
4. Create a remediation item for each `Fail`, with owner, severity, target date, compensating control, and acceptance criteria.
5. Validate the controls against the workload's business impact, SLOs, RTO/RPO, data classification, compliance obligations, and regional feature availability.
6. Reassess after material changes and on an agreed operational cadence.
7. Determine applicability per service and critical flow from the inventory, manifest outputs, and workload-owner confirmation. A missing collector output or failed discovery does not prove the service is absent. Record coverage limitations for unsupported resources and external dependencies.
8. For a resource-specific control, review every applicable instance and retain per-resource evidence. Assign `Fail` if any instance is proven noncompliant, otherwise `Not verified` if an applicable instance is unverified; assign `Pass` only when all applicable instances meet the control. An accepted risk does not turn a `Fail` into a `Pass`.
9. Treat the service guides as design guidance, not universal feature mandates. Justify tradeoffs against business requirements and verify current tier, region, namespace, feature compatibility and availability. Do not require premium tiers, multi-region replicas, customer-managed keys, immutable retention, or previews solely to pass a review.

### Applicability and pillar alignment

| Scope | Application |
|---|---|
| Workload-wide | Apply foundations and the relevant pillar/manual controls to the full workload, including SQL/Blob-only workloads. Evaluate common intent such as recovery, identity, monitoring, deployment safety and capacity against the services actually used. |
| Service-specific clauses in Sections 2–6 | App Service/Front Door/MySQL/cache recommendations apply only when that service or architecture is used. Do not impose MySQL features on Azure SQL Database. Use the service supplements for engine-specific requirements. |
| Application and runtime controls | Apply application, runtime, administrative-interface, scheduling and content-delivery controls only where those components exist. For mixed controls, document which clauses apply and assess those clauses; mark the entire control `N/A` only when none apply. |
| Azure SQL Database | Apply Section 7.11 to each logical server, database and pool as appropriate; use database-level requirements and inherited server policies together. |
| Blob Storage | Apply Section 7.12 to accounts, Blob services and relevant containers/data classes. A file-only storage account does not make Blob controls applicable. |
| Overlapping controls | Sections 2–6 state common outcomes; Section 7 adds service-specific acceptance criteria. Cross-reference shared evidence and remediation rather than creating duplicate backlog work. Section 9 counts each ID once. |

The new supplements label each control with its primary pillar through their subheadings. Reliability covers resilience and recovery; Security covers confidentiality, integrity and access; Cost Optimization balances lifecycle cost and business value; Operational Excellence covers safe change and observability; Performance Efficiency covers measured capacity and response targets. In the existing report format they remain in Section 7, not additional rows in Sections 2–6; do not double-count them in the overall score.

### Status and evidence key

| Status | Meaning |
|---|---|
| `Pass` | Evidence proves the control is implemented and operated as intended. |
| `Fail` | Evidence proves the control is not met or is ineffective. |
| `N/A` | The control does not apply; the rationale and approver are recorded. |
| `Not verified` | Evidence is unavailable, incomplete, or requires a manual test. |

## 1. Workload foundations and governance

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| FND-01 | Define workload, business, technical, security, data, and 24x7 incident owners. | Shared ownership or stale escalation contacts. | Ownership register, tags, support rota. | [ ] |
| FND-02 | Document critical user and system flows, dependencies, data flows, trust boundaries, regions, and failure modes. | Reviewing isolated Azure resources without the end-to-end workload. | Architecture and data-flow diagrams, dependency map. | [ ] |
| FND-03 | Rate critical flows and define measurable SLOs, SLIs, RTOs, RPOs, and accepted availability and data-loss risks. | Selecting redundancy or backup settings without business targets. | Business impact analysis, SLO and recovery documentation. | [ ] |
| FND-04 | Maintain a current threat model for the internet edge, origin bypass, supply chain, identities, secrets, data stores, admin paths, and exfiltration. | Treating WAF, private endpoints, or Defender as a substitute for threat modeling. | Threat model, risk register, remediation backlog. | [ ] |
| FND-05 | Classify data and map residency, access, encryption, retention, deletion, backup, and recovery requirements to each store and log. | Applying one protection level to all data or retaining sensitive data indefinitely. | Data inventory, classification policy, compliance assessment. | [ ] |
| FND-06 | Separate production and nonproduction resources where blast radius, policy, identity, data, or billing isolation requires it. | Mixing production data and identities with test environments without explicit controls. | Subscription and resource-group design. | [ ] |
| FND-07 | Use least-privilege Azure RBAC, Microsoft Entra ID, MFA, Conditional Access, PIM/JIT, access reviews, and a protected emergency-access path. | Standing Owner access, shared admins, or broad custom roles. | RBAC export, PIM settings, access-review evidence. | [ ] |
| FND-08 | Separate control-plane and data-plane duties, especially for subscription administration, Key Vault purge, and data-owner permissions. | Giving deployment identities unrestricted data or purge access. | Segregation-of-duties matrix and role assignments. | [ ] |
| FND-09 | Apply the current GA Microsoft cloud security benchmark through Defender for Cloud and Azure Policy, with time-bound, documented exceptions. Review other regulatory standards applicable to the organization and track control evidence separately. | Manual reviews as the only guardrail, permanent blanket exemptions, or treating MCSB compliance as proof of regulatory compliance. | Policy assignments, compliance results, exemption register, Defender regulatory-compliance dashboard. | [ ] |
| FND-10 | Review Defender for Cloud and Azure Advisor recommendations by attack path, exposure, business impact, severity, and cost; track decisions. | Chasing secure score alone or automatically applying every recommendation. | Review record, recommendation backlog, approved exceptions. | [ ] |
| FND-11 | Apply resource locks to critical stateful resources without blocking a documented break-glass recovery path. | No deletion protection or locks that prevent recovery automation. | Locks and emergency-change procedure. | [ ] |
| FND-12 | Enforce ownership, workload, environment, cost-center, and lifecycle tags; reconcile untaggable shared costs. | Untagged resources or tags that are not maintained. | Azure Policy, tag inventory, Cost Management export. | [ ] |
| FND-13 | Use Customer Lockbox (where supported, including App Service and MySQL Flexible Server) to review and approve or reject Microsoft support access requests to workload data. | Assuming Microsoft support never needs data access, or leaving Lockbox unconfigured for services that support it. | Customer Lockbox configuration and request history. | [ ] |

## 2. Reliability

Implements WAF reliability recommendations `RE:01`–`RE:10`.

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| REL-01 | Keep the architecture simple; document and justify every dependency, including Front Door, cache, Key Vault, DNS, and background processing. | Adding components that do not improve a stated business requirement. | Architecture decision records and dependency map. | [ ] |
| REL-02 | Perform failure-mode analysis for critical flows, including zone, region, App Service worker, MySQL, cache, storage, identity, DNS, certificate, Front Door, deployment, and network failures. | Assuming individual Azure SLAs prove workload recovery. | FMA and mitigation backlog. | [ ] |
| REL-03 | Run production on at least two App Service instances; use zone redundancy and sufficient instance count where supported and justified by SLO. Disable ARR affinity (sticky sessions) so requests distribute evenly. | A single-worker production site, a tier incapable of meeting availability targets, or sticky sessions masking a stateless-design gap. | Plan SKU, capacity, zone redundancy, regional capability, ARR-affinity setting. | [ ] |
| REL-04 | Enable Always On and use a fast, dependency-aware Health Check endpoint that removes unhealthy instances without disclosing sensitive data. Configure auto-heal rules for slow requests, memory limits, and HTTP error thresholds, and review the App Service Resiliency Score report. | A health endpoint that always returns 200, is expensive, or performs destructive work; no auto-heal configuration. | App Service configuration, Health Check/auto-heal settings, Resiliency Score report, synthetic test. | [ ] |
| REL-05 | Keep horizontally scaled application workers stateless; place durable data in an appropriate persistent store and design for cache/session loss. | Local session or uploaded-object state required for correctness after worker replacement or scale-out. | Application design, storage and cache configuration, failure test. | [ ] |
| REL-06 | Configure tested autoscale with minimum, maximum, triggers, cooldowns, quotas, and capacity headroom based on measured or forecast demand. | Manual-only scale-out, a minimum of one for critical production, or oscillating rules. | Autoscale profile, load test, quota review. | [ ] |
| REL-07 | Use warm-up (Application Initialization) and deployment health validation so a new instance or slot receives production traffic only when ready. | Sending user traffic to a cold or unhealthy worker. | Startup configuration, deployment logs, traces. | [ ] |
| REL-08 | Configure MySQL HA, backup retention, and geo-redundant backup according to RTO/RPO and regional recovery needs. | Assuming HA replaces backup or accepting default retention without analysis. | MySQL HA and backup configuration. | [ ] |
| REL-09 | Define a consistent recovery set for database, uploads/media, application and configuration, secrets, DNS, certificates, Front Door/WAF, and network policy. Use MySQL's native backup/restore for the database, not App Service's built-in backup feature (deprecated for linked databases). | Restoring the database and uploads from incompatible points in time, or relying on App Service backup for a linked database. | Recovery design and runbook. | [ ] |
| REL-10 | Test point-in-time restore, application/media restore, cache loss, slot rollback, and, where required, regional recovery; measure achieved RTO/RPO and rehearse failover procedures. | Marking a backup compliant solely because it exists. | Dated exercise report and remediation actions. | [ ] |
| REL-11 | Replicate Blob data with an LRS/ZRS/GRS/GZRS/RA option that meets durability and regional recovery requirements. | LRS for critical data without risk acceptance or geo-replication as the only deletion protection. | Storage SKU and recovery requirements. | [ ] |
| REL-12 | Enable data-protection features suitable for each object-data and backup class, such as soft delete, versioning, point-in-time restore, snapshots, or immutability, subject to feature compatibility and recovery requirements. | Assuming replication protects against accidental or malicious deletion. | Blob service data-protection configuration and approved recovery requirements. | [ ] |
| REL-13 | Configure Front Door origin health probes against a lightweight, dependency-aware endpoint and define deliberate priority, weight, and failover behavior. | Probing `/` or a cached response that hides dependency failure. | Origin-group configuration and failure test. | [ ] |
| REL-14 | Evaluate multi-region App Service, MySQL, storage, and Front Door routing only when required by the workload SLO; test data consistency and failover. | Multiple origins with unsynchronized state or untested failover. | DR architecture, data strategy, game-day record. | [ ] |
| REL-15 | Implement bounded retries, timeouts, idempotency, circuit breaking, and graceful degradation for MySQL, Redis, storage, Key Vault, email, and external APIs. | Unlimited retries or retry storms during dependency failure. | Application configuration, fault-injection tests, traces. | [ ] |
| REL-16 | Queue and control asynchronous work such as email, image processing, and large imports; include dead-letter and reconciliation handling where appropriate. | Running heavy asynchronous work on user request paths. | Queue design, retry policy, operations runbook. | [ ] |
| REL-17 | Monitor availability and reliability indicators for critical flows and dependencies, retain evidence, and use it for post-incident learning. | Resource metrics alone without user-flow health. | Availability tests, SLO dashboard, incident reviews. | [ ] |

Additional network and NAT Gateway reliability items are in [Section 7.6](#76-network-vnet-nsg-private-endpoints-private-dns) and [Section 7.7](#77-nat-gateway).

## 3. Security

Implements WAF security recommendations `SE:01`–`SE:12` and the applicable Microsoft cloud security benchmark controls.

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| SEC-01 | Maintain a security baseline aligned to the current Microsoft cloud security benchmark, the App Service security baseline, data classification, and regulatory requirements. | A one-time hardening exercise with no posture remeasurement. | Baseline, policy assignments, Defender compliance. | [ ] |
| SEC-02 | Apply secure development practices to application code, third-party components, dependencies, containers/packages and IaC, including secret and vulnerability scanning with risk-based patch SLAs. | Unsupported or unreviewed components, secret-bearing source, or ignored transitive vulnerabilities. | SBOM, scan results, patch records, CI/CD gates. | [ ] |
| SEC-03 | Use managed identities for Azure dependencies where supported, use Key Vault references for secrets, and grant only required data-plane permissions. | Database passwords, storage keys, or long-lived connection strings in app settings. | App identity, Key Vault references, RBAC and application design. | [ ] |
| SEC-04 | Use Microsoft Entra authentication for database clients where supported and appropriate; otherwise use a dedicated least-privilege database user, protect its credential in Key Vault and test rotation. | An application connecting as database administrator or using a shared permanent credential. | Entra setup or database grants, Key Vault, rotation test; service-specific SQL/MySQL controls. | [ ] |
| SEC-05 | Disable App Service basic publishing credentials, SCM basic authentication, remote debugging, and unused deployment endpoints (FTP or FTPS-only); restrict SCM separately. | Long-lived FTP/Git credentials, remote debugging enabled in production, or publicly reachable Kudu administration. | App Service configuration, access restrictions, Azure Policy. | [ ] |
| SEC-06 | Require HTTPS, TLS 1.2 or later (end-to-end TLS where supported), secure FTPS settings or no FTP, and supported application runtime and platform versions. | HTTP, legacy TLS, plain FTP, or unsupported runtime versions. | App configuration and runtime inventory. | [ ] |
| SEC-07 | Put Front Door Standard or Premium with WAF in front of the public site; associate the intended WAF policy with every production domain and route and use Prevention mode after tuning. | An unassociated WAF, permanent Detection mode, or disabled protection left unrestored. | Front Door routes, security policies, WAF logs. | [ ] |
| SEC-08 | Use current managed WAF rules, bot protection where supported, targeted rate limits, and narrow, reviewed exclusions. Evaluate Azure DDoS Protection Standard for any workload with public IP resources. | Disabling an entire rule group, keeping permanent broad exclusions, or assuming Front Door alone covers every public IP in the topology. | WAF policy, exclusions, approvals, test evidence, DDoS plan. | [ ] |
| SEC-09 | Prevent origin bypass. Prefer Front Door Premium Private Link; otherwise restrict App Service ingress to Front Door and validate the expected Front Door identifier. | A public origin directly reachable around WAF or trusting a spoofable header without source restrictions. | Private Link or App Service access restrictions and negative bypass test. | [ ] |
| SEC-10 | Restrict application login and administrative interfaces using identity, network, WAF and application controls as appropriate; explicitly review exceptions required by legitimate client flows. | Public password-only administrator access, unlimited login attempts, or blanket administrative-path exclusions. | Identity/WAF rules, admin access design, negative tests. | [ ] |
| SEC-11 | Integrate App Service outbound traffic with the intended VNet, DNS, routes, NSGs, and firewall/proxy controls; treat NAT Gateway as address translation, not a firewall. | Assuming VNet integration makes inbound traffic private or leaving uncontrolled egress. | VNet integration, routes, NSGs, firewall, egress test. | [ ] |
| SEC-12 | Use private connectivity and correct private DNS for MySQL, Blob Storage, Key Vault, Redis, and other supporting PaaS services when the risk model requires it; disable public paths after validation. | Private endpoint configured while public access remains unintentionally usable. | Private endpoints, DNS zones, service network settings, connectivity tests. | [ ] |
| SEC-13 | Segment networks and apply least-privilege ingress and egress rules; review effective rules and custom routes. | Flat networks, broad `Internet`/`*` allows, or an untested NVA dependency. | VNet topology, NSGs, effective rules, UDRs. | [ ] |
| SEC-14 | Store application signing/encryption keys, database credentials, SMTP credentials, certificates and other secrets in Key Vault; set expiry, rotation ownership, alerts and emergency rotation procedures. | Secrets in application configuration files, source control, tickets, logs, or nonexpiring values. | Key Vault inventory, expiration, alerts, rotation test. | [ ] |
| SEC-15 | Harden Key Vault with RBAC, least privilege, purge protection, soft delete, audit diagnostics, and private or restricted network access. | Broad access policies, no purge protection, or unprotected secret audit logs. | Vault configuration, RBAC, diagnostics, private endpoint. | [ ] |
| SEC-16 | Require encryption in transit and at rest for MySQL, Blob Storage, Key Vault, cache, and telemetry; use customer-managed keys only when requirements justify their added operational dependency. | Disabling TLS or deploying CMK without key lifecycle and recovery ownership. | Service encryption settings, Key Vault and recovery design. | [ ] |
| SEC-17 | Disable anonymous Blob access unless explicit public media exposure is approved; use Microsoft Entra ID and managed identity or short-lived least-privilege SAS where possible. | Account keys or nonexpiring broad SAS tokens in settings or URLs. | Storage settings, identity design, SAS governance. | [ ] |
| SEC-18 | Harden application and administrative surfaces: disable production debug output and in-application source editing, remove unused components, and restrict database consoles, diagnostic endpoints and unused remote interfaces. | Administrative code execution outside the release process, public backup/debug output, or unnecessary remote interfaces. | Runtime configuration, component inventory, administrative access review and application tests. | [ ] |
| SEC-19 | Apply restrictive CORS, CSP, HSTS, `X-Frame-Options`, and `X-Content-Type-Options` appropriate to the application; validate behavior rather than adding headers blindly. | Overly permissive origins or headers that break legitimate flows and are disabled later. | HTTP-header scan and regression tests. | [ ] |
| SEC-20 | Use least-privilege application roles, individual administrative identities, strong authentication/MFA and audited privileged access with periodic access reviews. | Shared administrative credentials, excessive privileges or unreviewed dormant accounts. | Application user/role review, identity controls and administrative audit records. | [ ] |
| SEC-21 | Enable Defender for Cloud plans justified by deployed services; route Defender security alerts into an owned SIEM or response process and test triage. | Paying for plans without coverage validation or alert ownership. | Defender pricing, coverage, alerts, workflow automation. | [ ] |
| SEC-22 | Enable security-relevant control-plane and data-plane diagnostics, prevent telemetry from collecting secrets or unnecessary PII, and protect the log destination. | No audit trail or sensitive request bodies, tokens, and credentials in logs. | Diagnostic settings, workspace RBAC, redaction tests. | [ ] |
| SEC-23 | Test WAF prevention, direct-origin bypass, authentication, authorization, admin protection, secret rotation, and security-alert response. | Declaring a configured control effective without an end-to-end test. | Security test results, WAF logs, incident exercise. | [ ] |
| SEC-24 | Verify application configuration integrity and environment/tenant isolation: correct dependency endpoints, secret references, filesystem permissions and domain-to-tenant mappings where used. | Default/insecure values, shared secrets across isolation boundaries, or settings copied unreviewed between environments. | App settings, Key Vault references, configuration/permission review and environment/tenant-isolation tests. | [ ] |

Additional network, NAT Gateway, monitoring, Communication Services, and Defender-specific security items are in [Section 7](#7-resource-specific-supplementary-checklist).

## 4. Cost Optimization

Implements WAF cost recommendations `CO:01`–`CO:14`.

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| CST-01 | Maintain a workload cost model covering normal, peak, failover, security, monitoring, backup, data transfer, and DR costs, with a documented business-value and availability tradeoff. | Budgeting only steady-state App Service and database list prices. | Cost model and approved budget. | [ ] |
| CST-02 | Create budgets, forecast thresholds, daily cost reviews, anomaly alerts, accountable recipients, and spending guardrails at subscription, resource-group, and workload scope. | Reviewing spend after invoice close or using unowned budget alerts. | Budgets, alerts, cost reports, review minutes. | [ ] |
| CST-03 | Right-size App Service plans from CPU, memory, request, latency, queue, and worker utilization while preserving SLO headroom. | Sustained overprovisioning or downsizing that breaks reliability targets. | Metrics, load tests, Advisor and cost analysis. | [ ] |
| CST-04 | Right-size MySQL compute, storage, IOPS, HA, backup, and cross-region transfer from measured demand; use stop/start only for eligible nonproduction servers. | Ignoring HA/backup costs or stopping a required production dependency. | MySQL metrics, schedule, cost model. | [ ] |
| CST-05 | Use autoscale scale-in and planned nonproduction schedules, and remove idle App Service plans, slots, public IPs, private endpoints, caches, test services, snapshots, and logs. | Production-sized dev environments operating continuously. | Inventory, schedules, utilization and cleanup record. | [ ] |
| CST-06 | Evaluate reservations, savings plans, enterprise agreements, and license benefits for stable baseline use; monitor commitment utilization and coverage. | Committing volatile demand or retaining unused commitments. | Reservation analysis and utilization report. | [ ] |
| CST-07 | Select Blob redundancy and access tiers from durability, access, retrieval, and lifecycle requirements; use narrow lifecycle policies for media, backups, logs, versions, and soft-deleted data. | Tiering data too quickly or using broad deletion rules without recovery validation. | Storage policy, inventory, cost analysis. | [ ] |
| CST-08 | Model Front Door tier, WAF, requests, rule processing, data transfer, Private Link, and logging costs; use safe caching and compression to reduce origin transfer. | Enabling edge features without measuring benefit or retaining every request log indefinitely. | Cost model, cache metrics, logging retention. | [ ] |
| CST-09 | Manage Azure Monitor and Log Analytics ingestion, sampling, transformations, table plans, archive, and retention according to actual query needs; keep workspace and Application Insights co-located to avoid cross-region transfer. | A daily cap as the primary cost strategy or perpetual verbose duplicate telemetry. | Workspace configuration, ingestion and retention trend, resource regions. | [ ] |
| CST-10 | Attribute cost across edge, compute, database, cache, storage, monitoring, security, network, backup, and messaging, then optimize the largest measured driver. | Optimizing minor resource costs while compute, database, or logging dominates. | Workload cost allocation and trend. | [ ] |
| CST-11 | Consolidate compatible applications and shared services only when their scaling, security, ownership, and SLO requirements are compatible. | One idle plan per app or co-hosting unrelated critical workloads solely to reduce spend. | Plan/service inventory, ownership and utilization. | [ ] |
| CST-12 | Optimize high-cost flows, media delivery, database queries, cache hit rate, and operational toil before adding capacity. | Scaling to hide inefficient code, database access, or administrative work. | Flow cost analysis, traces, database/cache metrics. | [ ] |
| CST-13 | Keep Defender, availability, security, backup, and DR spending that is required by the risk decision; review removal through formal risk acceptance, and check for duplicate third-party tooling. | Disabling high-value controls only to reduce visible service spend, or running overlapping tools with no use case. | Risk acceptance, control mapping, cost review. | [ ] |
| CST-14 | Train operators to use cost tooling and automate repeatable cost controls, reporting, lifecycle management, and cleanup. | Manual cost reporting with no action owner or automation. | Operating model, automation, review cadence. | [ ] |

Additional NAT Gateway and Communication Services cost items are in [Section 7.7](#77-nat-gateway) and [Section 7.9](#79-azure-communication-services).

## 5. Operational Excellence

Implements WAF operational excellence recommendations `OE:01`–`OE:11`.

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| OPS-01 | Define standard development, security, operations, incident, and change-management practices with clear accountability and continuous improvement. | Undocumented, person-dependent production operations. | Operating model, RACI, review and postmortem records. | [ ] |
| OPS-02 | Use version-controlled declarative IaC for Azure resources, policy, networking, DNS, Front Door/WAF, diagnostics, and configuration; detect drift. | Portal-only changes or unreviewed mutable scripts. | Repository, pull requests, pipeline and drift reports. | [ ] |
| OPS-03 | Drive application code, infrastructure, dependencies and configuration changes through automated pipelines with peer review, tests, promotion gates and traceable artifacts. | Direct production editing or untested automatic changes. | CI/CD definitions, release records, signed/versioned artifacts. | [ ] |
| OPS-04 | Use deployment slots where supported, slot-specific settings, warm-up and health validation, progressive exposure (swap with preview), and a tested rollback path. | Swapping an unhealthy slot, leaking slot settings, or irreversible database changes first. | Slot configuration, pipeline, swap and rollback test. | [ ] |
| OPS-05 | Keep database schema changes backward compatible with blue/green or slot rollout; plan and test data migration and rollback behavior. | Destructive production schema migration coupled to an unvalidated release. | Migration plan, deployment tests, rollback evidence. | [ ] |
| OPS-06 | Establish configuration baselines for App Service, MySQL parameters, Front Door/WAF, storage, Key Vault, Redis, and diagnostics; alert on drift. | Undocumented portal changes or inconsistent production and staging controls. | Baseline export, policy, drift report. | [ ] |
| OPS-07 | Enable application, web server, platform, WAF, access, health probe, MySQL, storage, Key Vault, cache, and network diagnostics with purposeful retention and centralized analysis. | Missing incident evidence or indefinite high-volume logging with no use case. | Diagnostic settings, workspace design, retention. | [ ] |
| OPS-08 | Instrument requests, dependencies, exceptions, distributed traces, business metrics, deployment markers, availability tests, and user-visible SLO symptoms. | Monitoring CPU alone or missing critical-flow behavior. | Application Insights, dashboards, availability tests. | [ ] |
| OPS-09 | Define actionable alerts with owners, severity, routing, deduplication, runbooks, and regular notification tests for errors, latency, saturation, availability, certificates, secrets, quota, and lifecycle events. | Alert storms, dashboards with no owner, or alerts that no one tests. | Alert rules, action groups, runbooks, test records. | [ ] |
| OPS-10 | Maintain service-specific runbooks for failed deployments, compromised identities/components, database failover/restore, object recovery, cache loss, secret/certificate rotation and network failures; include WAF false positives/origin bypass where used. | A generic incident plan without workload-specific actions, owners and validation steps. | Runbooks and exercise records. | [ ] |
| OPS-11 | Establish a structured incident process for detection, diagnosis, communications, recovery, post-incident learning, and remediation ownership. | Incident response limited to portal visibility or a single administrator. | Incident plan, on-call rota, postmortems. | [ ] |
| OPS-12 | Perform unit, integration, end-to-end, security, backup/restore, performance, operational and deployment tests in CI/CD with explicit acceptance criteria. | Resource deployment tests only, without proving critical workload flows and data integrity. | Test suites, pipeline results, release gates. | [ ] |
| OPS-13 | Track application runtimes, dependencies, database engines, Azure services, certificates, secrets, domains, quotas and service-retirement notices (including legacy Azure Cache for Redis retirement). | Unsupported runtimes or discovering expiry and retirement during an incident. | Lifecycle register, Service Health alerts, inventory. | [ ] |
| OPS-14 | Govern runtime, dependency and platform updates with compatibility review, representative preproduction testing, controlled rollout, health validation and a recovery path. | Uncontrolled automatic production changes or updates with no application compatibility assessment. | Update policy, staging test, release/maintenance record and recovery procedure. | [ ] |
| OPS-15 | Create workbooks and dashboards for health, traffic, WAF activity, availability, database, cache, storage, cost, and security posture; review them regularly. | Dashboards without operational decisions or review ownership. | Workbooks, saved queries, review cadence. | [ ] |
| OPS-16 | Automate reliable, secure, and maintainable routine tasks such as validation, configuration export, cleanup, certificate/secret notifications, and recovery checks. | Manual procedures repeated without validation or audit trail. | Automation code, schedules, run history. | [ ] |
| OPS-17 | Where the workload sends email, use Azure Communication Services or an approved delivery provider; validate sender domain, SPF/DKIM/DMARC, delivery, bounce handling and retry behavior. | Unmanaged local mail delivery, unverified sender domains, or treating send API success as confirmed delivery. | Provider configuration, DNS records, delivery reports, runbook. | [ ] |

Additional network, NAT Gateway, monitoring, and Defender governance items are in [Section 7](#7-resource-specific-supplementary-checklist).

## 6. Performance Efficiency

Implements WAF performance efficiency recommendations `PE:01`–`PE:12`.

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| PRF-01 | Define numerical performance targets for critical flows, including availability, P50/P95/P99 response time, TTFB, throughput, error rate, and cache behavior. | Vague performance goals or optimizing noncritical pages first. | Performance budget, SLO dashboard. | [ ] |
| PRF-02 | Perform capacity planning before anticipated marketing events, seasonal traffic, launches, growth, or regulatory deadlines. | Scaling only after user-visible saturation. | Forecast, load test, capacity plan. | [ ] |
| PRF-03 | Select App Service, MySQL, Redis, storage, and Front Door SKUs/tier features that can meet workload targets and expected capacity changes. | Burstable assumptions for sustained production demand or costly tiers with no measured need. | SKU rationale, metrics, load test. | [ ] |
| PRF-04 | Measure end-to-end latency, throughput, errors, saturation, dependency timing, queueing, cache hit rate, and database performance consistently over time. | Monitoring CPU alone or comparing inconsistent time periods. | Application Insights, Azure Monitor, query dashboards. | [ ] |
| PRF-05 | Implement controlled scale-out and partitioning; validate App Service autoscale, MySQL limits, cache capacity, SNAT capacity, and Front Door origin behavior under load. | Scale thresholds that oscillate or dependency limits ignored by app scaling. | Load test, autoscale and dependency metrics. | [ ] |
| PRF-06 | Load, stress, soak, cache-invalidation, and failure-mode test production-like critical flows at expected peak and growth traffic, using Azure Load Testing or an equivalent tool. | Happy-path average-load testing only. | Versioned test scripts, reports, remediation backlog. | [ ] |
| PRF-07 | Use Front Door caching only for explicitly cache-safe content. Design cache keys, query handling, TTLs, invalidation, and cookie behavior to avoid leaking personalized or authenticated responses. | Caching admin, private, or query-dependent content without validation. | Front Door rules, cache tests, HTTP headers. | [ ] |
| PRF-08 | Where web content is served, evaluate edge caching and object-storage offload for static assets/uploads; use suitable compression and supported HTTP versions based on client compatibility and measured benefit. | Serving all static data through application workers or compressing already-compressed content blindly. | Edge route, Blob integration, response headers and before/after metrics. | [ ] |
| PRF-09 | Use object and page caching deliberately, with Azure Managed Redis or Azure Cache for Redis where appropriate; test reconnect, timeouts, cache miss, eviction, and cache-loss behavior. | A new Redis connection per request or application failure when cache is unavailable. | Cache configuration, metrics, fault test. | [ ] |
| PRF-10 | Profile and tune runtime execution, compilation/caching where supported, startup behavior, component overhead and payload size against workload latency and resource targets. | Applying runtime-specific tuning blindly, unbounded component overhead or undocumented startup changes. | Runtime/server configuration, dependency profiles and representative performance tests. | [ ] |
| PRF-11 | Run scheduled/background processing through an appropriate managed scheduler or worker mechanism; control concurrency, retries and duplicate execution and monitor duration, backlog and failures. | Heavy periodic processing on user request paths or schedules with no ownership and failure handling. | Scheduler/worker configuration, concurrency policy, job logs and recovery tests. | [ ] |
| PRF-12 | Optimize MySQL indexes, queries, connections/connection pooling, storage/IOPS, and slow-query handling before scaling compute; keep app and database appropriately co-located and in the same region to minimize latency. | Treating database scale-up as the only performance remedy. | Slow-query log, Query Store/metrics, query review. | [ ] |
| PRF-13 | Monitor and minimize the performance effects of backup, reindexing, security scans, secret rotation, deployments, and operational tasks. | Running maintenance during critical traffic without capacity or impact planning. | Schedule, telemetry, change records. | [ ] |
| PRF-14 | Define a live performance incident process with clear responsibilities, telemetry, mitigations, and follow-up optimization. | Ad hoc troubleshooting without a recovery or learning path. | Performance runbook and incident records. | [ ] |
| PRF-15 | Continuously optimize components that degrade over time, including application dependencies, database tables/indexes, cache behavior, storage lifecycle and networking; watch for Busy Front End, No Caching and Noisy Neighbor anti-patterns. | Treating a one-time tuning exercise as permanent capacity planning. | Trend reports, optimization backlog. | [ ] |

Additional network, NAT Gateway, and monitoring performance items are in [Section 7.6](#76-network-vnet-nsg-private-endpoints-private-dns), [Section 7.7](#77-nat-gateway), and [Section 7.8](#78-application-insights-and-log-analytics).

## 7. Resource-specific supplementary checklist

These items add resource-level depth for services that a single pillar row cannot fully capture. Use them alongside Sections 2–6, not instead of them.

### 7.1 App Service plan, web app, and slots

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| APP-01 | Protect nonpublic slots with equivalent authentication, network restrictions, TLS, diagnostics, and secret handling as production. | A staging slot that bypasses production WAF/authentication or contains production secrets unnecessarily. | Slot `auth`, `accessRestrictions`, settings and diagnostics. | [ ] |
| APP-02 | Review co-hosted apps on a shared plan for noisy-neighbor and correlated-failure risk; isolate apps with different scaling/security/SLO needs. | Packing unrelated critical apps into one plan only to reduce cost. | Plan `apps`, per-app metrics and ownership. | [ ] |

### 7.2 Azure Database for MySQL Flexible Server

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| SQL-01 | Apply least privilege in Azure RBAC and MySQL roles; separate schema migration, application read/write, reporting, and administration identities. | Application connects as server admin, or wildcard grants are permanent. | Role assignments and MySQL grant review. | [ ] |
| SQL-02 | Set and test a maintenance window; ensure the application reconnects automatically during failover/maintenance. | Maintenance scheduled at peak business time, or clients that require manual restart after failover. | Maintenance config and failover test. | [ ] |
| SQL-03 | Size storage and IOPS with headroom and alerts; account for storage auto-grow behavior and the inability to shrink storage directly. | Waiting for storage saturation, or overallocating permanently without review. | Storage/IO metrics and capacity plan. | [ ] |
| SQL-04 | Add explicit primary keys to every InnoDB table (turn on generated invisible primary keys, GIPK, for tables that lack one). Confirm the Burstable tier is not expected to support HA, read replicas, or accelerated logs. | Missing primary keys, which slow binary-log replication and HA failover and can trigger known replication bugs; assuming the Burstable tier supports HA/replicas. | Schema review, GIPK setting, tier selection rationale. | [ ] |

### 7.3 Key Vault

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| KV-01 | Separate vaults by environment, workload, region, and administrative boundary where blast radius or policy differs. | One organization-wide vault containing unrelated production and development secrets. | Vault inventory and architecture. | [ ] |
| KV-02 | Design applications for Key Vault throttling/transient faults; cache secrets securely for an appropriate period instead of calling Key Vault on every request. | Calling Key Vault repeatedly in hot paths, or caching secrets indefinitely with no refresh. | Traces, retry/cache design and load test. | [ ] |

### 7.4 Azure Managed Redis / Azure Cache for Redis

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| RDS-01 | Identify every legacy Azure Cache for Redis instance and execute a tested migration plan to Azure Managed Redis before the applicable retirement date. | Creating new legacy caches, or waiting until service disablement to migrate. | Resource type/SKU, retirement register and migration test. | [ ] |
| RDS-02 | Choose an eviction policy deliberately, keep cached values appropriately sized, reserve memory where applicable, and scale before saturation. | Scaling only after server load/memory is already critical, or caching very large objects indiscriminately. | Redis config, key sampling and load tests. | [ ] |
| RDS-03 | Keep authentication enabled on every cache; never set the `AuthNotRequired` property (or equivalent access-key-disabled setting) to allow unauthenticated access. | Disabling authentication entirely to simplify client configuration. | Redis access configuration and `AuthNotRequired` setting. | [ ] |

### 7.5 Azure Front Door and WAF

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| FD-01 | Use Front Door Standard/Premium rather than the classic (retiring) offering, and select Premium where managed WAF rules and origin Private Link are required. | Remaining on a retiring classic offering, or selecting tier solely on price. | Profile SKU and lifecycle register. | [ ] |
| FD-02 | Select origin routing and session affinity from application behavior; prefer stateless distribution over sticky sessions. | Sticky sessions used to conceal local session state or unhealthy instance behavior. | Origin-group settings and architecture. | [ ] |
| FD-03 | Preserve the same host name between Front Door and the origin (forward the original host header) and restrict Front Door RBAC to only the identities that need control-plane access. | Rewriting the host header without validating cookie/redirect/session behavior, or leaving Front Door profile RBAC unrestricted. | Front Door host-header/origin configuration, RBAC assignments, regression test. | [ ] |

### 7.6 Network (VNet, NSG, private endpoints, private DNS)

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| NET-01 | Design address space with growth/peering/private-endpoint capacity and avoid overlaps with connected networks. | Nearly exhausted subnets, or overlapping ranges discovered during DR/merger connectivity. | IP address management plan and subnet utilization. | [ ] |
| NET-02 | Test private DNS resolution and routing from every client path, including peered VNets, build agents, and on-premises networks. | A private endpoint declared healthy because it resolves only from one VNet. | DNS/routing tests and topology. | [ ] |
| NET-03 | Review custom routes and network virtual appliance (NVA) dependencies for zone/region failure and asymmetric routing. | A single NVA or an incorrect UDR that silently blackholes production traffic. | Route tables, effective routes and failover test. | [ ] |
| NET-04 | Enable Network Watcher/flow logging where required and protect the logs; evaluate Azure DDoS Network Protection for VNets with public-IP resources. | Logging without retention/analysis, or assuming Front Door alone protects every public endpoint in the VNet. | Flow logs, DDoS plan and public-IP inventory. | [ ] |
| NET-05 | Measure network latency, throughput, connection count, DNS resolution time, packet drops, and route changes; keep dependent services appropriately close. | Assuming Azure backbone placement guarantees application latency. | Network Watcher, Connection Monitor and traces. | [ ] |
| NET-06 | Review idle private endpoints, public IPs, peerings, DNS Resolver instances, firewalls, flow logs, and interregion/egress transfer for removal. | Keeping unused network resources because their individual cost appears small. | Inventory and network cost report. | [ ] |
| NET-07 | Manage network and DNS changes as code with pre/post connectivity tests and a rollback path. | Manual NSG/UDR/DNS edits during incidents without effective-rule validation. | IaC, pipeline and change records. | [ ] |

### 7.7 NAT Gateway

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| NAT-01 | Associate the gateway only with intended private subnets and use predictable public IP prefixes for downstream allowlists. | NAT attached to the wrong subnet, or destination allowlists based on undocumented ephemeral addresses. | `show`, `subnetAssociations`, public IP resources. | [ ] |
| NAT-02 | Use NAT Gateway StandardV2 automatic zone redundancy where supported/appropriate; otherwise understand the Standard SKU's zonal placement and failure implications. | Calling a zonal Standard gateway zone-redundant. | SKU, zone and regional support. | [ ] |
| NAT-03 | Size public IP/SNAT capacity and connection limits; monitor failed/total SNAT connections and datapath availability. | Waiting for intermittent timeouts before assessing port exhaustion. | Metrics, alerts and capacity calculation. | [ ] |
| NAT-04 | Reuse/pool outbound connections, close them correctly, use bounded backoff, and avoid unnecessarily high idle timeouts; use Private Link/service endpoints for Azure PaaS traffic to free SNAT capacity. | New TCP connection per request, aggressive retries, long idle connections, or sending all PaaS traffic through NAT by default. | Application client settings, connection metrics, dependency endpoints. | [ ] |
| NAT-05 | Review gateway hourly/data-processing/public IP costs against actual subnet use; remove unattached or idle gateways and IPs. | A dedicated gateway for an idle environment with no egress requirement. | Association, flow/metric and cost data. | [ ] |
| NAT-06 | Enable supported flow logs/diagnostics and alert on datapath degradation, failed connections, drops, saturation, and resource health. | No telemetry for intermittent outbound failures. | `diagnosticSettings`, metrics, alerts and runbook. | [ ] |

### 7.8 Application Insights and Log Analytics

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| MON-01 | Use workspace-based Application Insights, Microsoft Entra/RBAC, managed identity where supported, and least-privilege query/export access. | Sharing instrumentation/API keys broadly, or granting all engineers unrestricted sensitive-log access. | `show`, workspace link and `roleAssignments`. | [ ] |
| MON-02 | Use Azure Monitor Private Link Scope (AMPLS) when private ingestion/query is required, and configure public access deliberately. | Private application dependencies but unrestricted public monitoring endpoints without review. | Workspace network settings and AMPLS design. | [ ] |
| MON-03 | Separate operational and security workspaces when access, retention, residency, Sentinel billing, or blast-radius requirements differ. | One workspace by habit, or excessive workspace sprawl with no governance. | Workspace strategy and RBAC. | [ ] |
| MON-04 | Create availability tests from multiple relevant locations and alert on user-visible symptoms and critical dependency failure. | Testing only the home page from one location, or relying on platform resource health alone. | Availability tests, action groups and runbooks. | [ ] |
| MON-05 | Use consistent correlation and SDK/OpenTelemetry versions across components; monitor telemetry throttling/drop and ingestion latency. | Mixed correlation schemes or unsupported SDKs that break end-to-end traces. | SDK inventory, telemetry health and trace sample. | [ ] |
| MON-06 | Monitor workspace health, ingestion volume, query performance, data collection rules, retention changes, and diagnostic-setting drift. | Discovering missing logs only after an incident. | Workspace health alerts and policy compliance. | [ ] |
| MON-07 | Use one Application Insights resource per workload per environment (for example, separate resources for dev, staging, and production), and deploy it in the same region as its Log Analytics workspace. | Sharing one Application Insights resource across environments, which mixes telemetry and configuration/security controls across environment boundaries. | Application Insights resource inventory, region placement. | [ ] |

### 7.9 Azure Communication Services

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| ACS-01 | Prefer managed identity/Microsoft Entra for supported operations; protect and rotate access keys/connection strings when keys remain necessary. | Communication Services keys in source code, client-side code, tickets, or unprotected app settings. | `show`, identities, RBAC and secret store. | [ ] |
| ACS-02 | Apply least-privilege RBAC and separate the application's sending identity from resource administrators. | Application identity has Contributor/Owner on the Communication Services resource. | `roleAssignments` and identity design. | [ ] |
| ACS-03 | Validate data residency/privacy requirements and obtain consent for communications; minimize message metadata/content retained in logs. | Sending regulated data without residency/consent review, or logging full message bodies. | Privacy assessment and logging schema. | [ ] |
| ACS-04 | Handle throttling and transient errors with bounded retries, idempotency/deduplication, status callbacks, and a dead-letter/reconciliation workflow. | Blindly retrying sends and producing duplicate email/SMS. | Client policy, message IDs and failure test. | [ ] |
| ACS-05 | Budget and alert by channel, destination, volume, and failed/retried sends to prevent abuse-driven spend. | No spend guardrail for compromised send credentials or retry storms. | Cost analysis, quotas and anomaly alerts. | [ ] |

### 7.10 Defender for Cloud and Azure Policy

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| DEF-01 | Verify Foundational CSPM/Defender CSPM state, MCSB assignment, secure-score controls, recommendations, attack paths, and governance rules at every in-scope subscription. | Assuming Defender is enabled because the portal opens, or because one subscription is covered. | `pricing`, security settings, assessments and compliance. | [ ] |
| DEF-02 | Confirm each paid Defender plan maps to present resource types and intended protections; verify subplans/extensions and coverage status. | Paying for irrelevant plans, or believing a top-level plan name guarantees every resource is protected. | `pricing`, plan settings and coverage workbook. | [ ] |
| DEF-03 | Review recommendation exemptions for scope, justification, compensating controls, owner, expiry, and revalidation. | Permanent subscription-wide exemptions with no expiry. | `exemptions` and exception register. | [ ] |
| DEF-04 | Use continuous export/workflow automation/SIEM integration where required and protect exported data. | Security findings retained only in the portal with no case-management path. | Automation/export settings and incident workflow. | [ ] |
| DEF-05 | Review protected-resource counts, per-resource/per-transaction charges, Defender CSPM benefits, and duplicate third-party tooling. | Disabling high-value detection without risk review, or running overlapping tools with no use case. | Defender cost report and control mapping. | [ ] |
| DEF-06 | Set governance rules, owners, and due dates; review secure-score trend and test incident procedures; monitor plan/configuration changes. | A static quarterly screenshot used as the security program. | Governance rules, secure-score trend and review minutes. | [ ] |

### 7.11 Azure SQL Database

Based on [Well-Architected guidance for Azure SQL Database](https://learn.microsoft.com/en-us/azure/well-architected/service-guides/azure-sql-database), reviewed 2026-10-21. These controls cover Azure SQL Database, not MySQL. Evidence filenames below are resolved through the manifest; `sections.<name>` means the named section in that resource document. Configuration is only partial evidence for controls that also require a design decision or operational test.

#### Reliability — Azure SQL Database

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| AZSQL-01 | Select the database/pool tier, compute model, zone redundancy and replica capacity from documented availability targets and failure-mode analysis; verify regional/tier support and recovery capacity. | Assuming every tier has identical failover behavior or buying Business Critical/Hyperscale without a requirement. | `azure-sql-database-*.json` and `azure-sql-elastic-pool-*.json`: `sections.show` (SKU, zone redundancy, replica settings where exposed); approved SLO and capacity analysis. | [ ] |
| AZSQL-02 | Where regional recovery is required, configure active geo-replication or failover groups with appropriate secondary capacity, failover policy and listener usage; test failover/failback, DNS, application reconnection and accepted asynchronous data loss. | Treating zone redundancy as regional DR, assuming zero RPO for geo-replication, or leaving application connections tied to the old primary. | Server `sections.failoverGroups`, database `sections.replicationLinks`; DR design and dated measured RTO/RPO test. | [ ] |
| AZSQL-03 | Set native automated backup redundancy, point-in-time retention and long-term retention to recovery, residency and compliance requirements; evaluate supported backup immutability and test restore and CMK availability when used. | HA/replication as a backup substitute, untested backups, or locking immutable retention before approving its irreversible consequences. | Database `sections.show`, `sections.shortTermRetention`, `sections.longTermRetention`; retention policy and dated native restore/key-recovery test. Immutability needs additional evidence when not returned. | [ ] |
| AZSQL-04 | Use supported database drivers with bounded transient-error retries/backoff, timeouts, safe transaction retry semantics and connection pooling; isolate critical and background connection pools where contention threatens availability. | Retrying non-idempotent transactions blindly, retry storms, or a background job exhausting user-facing connections. | Application client/transaction configuration, pool metrics and fault/maintenance tests; not established by management-plane collection. | [ ] |

#### Security — Azure SQL Database

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| AZSQL-05 | Prefer Microsoft Entra authentication and managed identities; enable Entra-only authentication where client compatibility permits and govern any SQL-authentication exception. Separate application, migration, reporting and administration database permissions. | An application using the server administrator, broad database grants, or assuming Azure RBAC establishes SQL data-plane permissions. | Server `sections.entraAdministrators`, `sections.entraOnlyAuthentication`, `sections.show`, `sections.roleAssignments`; database user/role grants and sign-in/rotation tests supplied separately. | [ ] |
| AZSQL-06 | Restrict network access to approved client paths; prefer Private Link with validated private DNS where required, disable unnecessary public access and review server/database firewall and VNet rules, including broad Azure-services exceptions. | A private endpoint with an unintended usable public path or unrestricted `0.0.0.0` Azure-services access. | Server `sections.show`, `sections.firewallRules`, `sections.virtualNetworkRules`, network evidence; database-scoped firewall export and positive/negative connectivity tests supplied separately. | [ ] |
| AZSQL-07 | Enforce minimum TLS 1.2 or a newer supported version and require clients to encrypt connections and validate server certificates. Validate compatibility before raising the minimum version. | Assuming a server minimum proves clients validate certificates, or permitting certificate-trust bypass. | Server `sections.show` (minimal TLS version); client connection policy and TLS/certificate tests without exposing credentials. | [ ] |
| AZSQL-08 | Verify TDE and choose service-managed or customer-managed protection from data requirements; when CMK is used, establish least-privilege key access, rotation, soft delete/purge protection and tested key recovery. | Treating TDE as column-level protection or deploying CMK without the ability to recover/decrypt backups. | Database `sections.transparentDataEncryption`, server `sections.encryptionProtector`, Key Vault evidence; encryption/key-lifecycle design and recovery test. | [ ] |
| AZSQL-09 | Use data classification to decide whether Always Encrypted/secure enclaves, row-level security or ledger are required, then validate application access and the intended confidentiality or tamper-evidence guarantee. | Treating dynamic data masking as an authorization boundary or imposing advanced features with no use case. | Classification and threat model, schema/security configuration, supported-feature assessment and application authorization tests; manual evidence required. | [ ] |
| AZSQL-10 | Establish effective server/database auditing, protected destinations and retention; validate event delivery. Verify Defender for SQL coverage, vulnerability assessment remediation and owned threat-alert response where required by risk. | Assuming a subscription plan proves database coverage, duplicate auditing with no benefit, or an enabled policy with no received events. | Server/database `sections.auditing`, `sections.diagnosticSettings`, Defender `sections.pricing`/`sections.assessments`; audit samples, SQL coverage/scan results and incident tests supplied separately. | [ ] |

#### Cost Optimization — Azure SQL Database

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| AZSQL-11 | Compare supported purchasing/compute models and service tiers against measured demand; evaluate serverless for intermittent workloads only when its supported scaling/auto-pause behavior and resume latency meet requirements. | Assuming every serverless configuration auto-pauses or sizing from average CPU alone. | Database `sections.show` (SKU, compute model, minimum capacity, auto-pause when exposed); utilization, pricing model and resume/load tests. | [ ] |
| AZSQL-12 | Use elastic pools only for databases with compatible governance and complementary demand; size pool capacity and per-database limits for peak concurrency and noisy-neighbor risk. | Pooling simultaneously busy or unrelated critical databases solely to lower cost. | Server `sections.elasticPools`, database/pool `sections.show`; per-database/pool utilization, cost comparison and saturation test. | [ ] |
| AZSQL-13 | Budget compute, replicas, storage, PITR/LTR backup growth, auditing, Defender and transfer; right-size from measured use and evaluate reserved capacity/Azure Hybrid Benefit only with stable demand and verified eligibility. | Quoting headline savings without utilization, reducing required retention for cost alone, or claiming unlicensed benefits. | Database `sections.show`, retention sections; cost exports, change-rate/backup consumption, licensing entitlement and commitment review. | [ ] |

#### Operational Excellence — Azure SQL Database

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| AZSQL-14 | Manage logical servers, databases, pools, network/authentication, backup and audit policies through versioned IaC with Azure Policy, peer review and drift detection; use controlled, backward-compatible schema releases. | Portal-only configuration or destructive schema changes with no tested rollout/rollback strategy. | IaC/SQL project, pipeline and policy-compliance results, schema migration tests; collected configuration is a baseline, not proof of change governance. | [ ] |
| AZSQL-15 | Monitor database and pool health, CPU/IO/storage, workers/sessions, failed connections, blocking/deadlocks, replication and user-flow symptoms; configure owned alerts and verify delivery and telemetry retention. | Resource dashboards with no actionable alerts or assuming diagnostic settings prove Query Store/database-watcher coverage. | `sections.diagnosticSettings`; Azure Monitor/database watcher/Query Store evidence, alert configuration and notification tests supplied separately. | [ ] |
| AZSQL-16 | Document maintenance behavior and supported maintenance-window choices; rehearse database restore, failover, credential/key loss and deployment rollback with application owners, including dependencies outside the resource group. | Assuming managed infrastructure removes database/application recovery responsibilities. | Database/pool `sections.show` (maintenance configuration if exposed); Service Health subscriptions, runbooks and dated exercises with measured outcomes. | [ ] |

#### Performance Efficiency — Azure SQL Database

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| AZSQL-17 | Establish latency/throughput targets and load-test database/pool limits, including CPU, data/log IO, storage, workers and sessions; prove headroom and supported scaling behavior at expected peak. | App Service scale-out exceeding database limits or assuming a successful SKU change proves performance. | Database/pool `sections.show`; time-series metrics, capacity forecast, load/scale test and SLO comparison. | [ ] |
| AZSQL-18 | Use Query Store and query-performance analysis to identify expensive queries, regressions, indexing/statistics issues, blocking and deadlocks; evaluate automatic tuning with an owned validation and rollback process. | Scaling compute to hide poor queries or assuming automatic tuning is configured because SQL Database supports it. | Query Store settings/history, execution plans, tuning decisions and before/after metrics; not collected by current scripts. | [ ] |
| AZSQL-19 | Tune client connection pooling, request concurrency, batching, driver versions and regional placement; evaluate supported connectivity policy and read-only routing/replicas against latency, consistency and network requirements. | One connection per request, unbounded pools, or sending consistency-critical reads to lagging replicas. | Server/database configuration and replication evidence; client settings, routing design and measured connection/read latency. | [ ] |
| AZSQL-20 | Test workload-appropriate database parallelism, read-scale/in-memory features and maintenance/auditing overhead before enabling or changing them; retain performance baselines and rollback criteria. | Universal MAXDOP values, feature adoption without tier support, or tuning that sacrifices required audit coverage. | Database-scoped settings and feature-support review, representative benchmark and maintenance/audit impact measurements; manual evidence required. | [ ] |

### 7.12 Azure Blob Storage

Based on [Well-Architected guidance for Azure Blob Storage](https://learn.microsoft.com/en-us/azure/well-architected/service-guides/azure-blob-storage), reviewed 2026-10-21. Apply by storage account, Blob service and container/data class. Validate account kind, hierarchical namespace (HNS), blob type and regional compatibility before recommending versioning, point-in-time restore, object replication, archive or backup features. SDK recommendations below apply to workload application code, not to the PowerShell/Azure CLI evidence collectors.

#### Reliability — Azure Blob Storage

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| BLOB-01 | Select LRS/ZRS/GRS/GZRS and optional secondary read access from documented zone/region failure, durability, availability, residency and RTO/RPO requirements; justify accepted residual risks. | Assuming geo-redundancy is synchronous, every SKU permits secondary reads, or all data requires the most expensive redundancy. | `storage-*.json`: `sections.show` (SKU, primary/secondary locations, account kind); failure-mode analysis and recovery requirements. | [ ] |
| BLOB-02 | For regional recovery, define failover/failback ownership, supported procedures, replication lag/last-sync checks and data reconciliation. For read-access replicas, test client switching, stale-read tolerance and graceful degradation. | Treating an RA secondary as writable or triggering unplanned failover without evaluating possible data loss. | Storage `sections.show`, Blob `sections.objectReplicationPolicies`; additional replication-status/last-sync evidence and dated failover/application tests. Object replication is not account failover. | [ ] |
| BLOB-03 | Configure compatible container/blob soft delete, versioning and point-in-time restore to approved recovery windows; protect against accidental overwrite/deletion and prove recovery of representative objects and containers. | Assuming replication prevents deletion, applying unsupported HNS/blob-type combinations, or marking recovery proven from enabled settings alone. | `blob-storage-*.json`: `sections.show` (retention, versioning, restore/change-feed settings); protection matrix and dated restore test. | [ ] |
| BLOB-04 | Evaluate isolated/vaulted backup or another independent recoverable copy for source-account loss/ransomware requirements; include identity, Key Vault, DNS, network and edge dependencies in the recovery set. | Counting same-account versions as isolated backup or assuming an account lock prevents data-plane deletion. | Backup design, current support matrix, vault/policy/job evidence and alternate-account recovery exercise; vault/backup status is not collected by current scripts. | [ ] |

#### Security — Azure Blob Storage

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| BLOB-05 | Disable account-level anonymous Blob access unless explicitly approved for public data; validate every relevant container's exposure and any static-website/edge delivery path independently. | Inferring private data from one private container or assuming the anonymous Blob setting secures the static website endpoint. | Storage `sections.show`, Blob `sections.containers` and `sections.show`; approved public-data inventory and unauthenticated access tests. | [ ] |
| BLOB-06 | Prefer Entra ID/managed identity with least-privilege Blob data roles and ACLs where applicable; disallow Shared Key when dependencies permit. Govern any necessary SAS with narrow permissions, short expiry, HTTPS and revocation/expiry policy. | Broad account/service SAS, permanent keys, equating management RBAC with data access, or assuming disabling Shared Key blocks user-delegation SAS. | Storage `sections.show` (shared-key/SAS policy), account/service `sections.roleAssignments`; container-scoped roles, HNS ACLs, application identity and SAS issuance policy supplied separately. Never include tokens. | [ ] |
| BLOB-07 | Restrict public network access and firewall exceptions to approved clients; use private endpoints and validated DNS where required, and evaluate both Blob and DFS endpoints for HNS workloads. | A private endpoint with an open public path, broad trusted-service exceptions, or treating CORS as an authorization control. | Storage `sections.show`/`sections.networkRules`, network evidence, Blob `sections.show` (CORS); endpoint/DNS and denied-client tests. | [ ] |
| BLOB-08 | Require secure transfer and minimum TLS 1.2 or a newer supported version; verify encryption at rest and govern CMK/encryption scopes only when needed, including key access, rotation and recoverability. | HTTP access, unsupported TLS requirements, or CMK/scopes with no lifecycle owner. | Storage `sections.show` (HTTPS/TLS/encryption), Key Vault evidence; client TLS tests and additional encryption-scope/key-recovery evidence when applicable. | [ ] |
| BLOB-09 | Apply retention/legal holds and appropriately locked immutable policies to data that requires WORM protection; separate administrative duties and validate deletion protection and lawful expiry before locking. | Immutability on the wrong container, irreversible retention without approval, or treating a legal-hold indicator as proof of full policy enforcement. | Blob `sections.containers` (immutability/legal-hold indicators), account `sections.locks`; detailed policy mode/retention/hold records and enforcement test supplied separately. | [ ] |
| BLOB-10 | Verify Defender for Storage coverage and applicable threat/malware protections, owned response and protected data-plane logs; restrict cross-tenant object replication unless approved by data-governance requirements. | Assuming a plan name proves effective protection or allowing replication to an unreviewed tenant/destination. | Storage `sections.show` (cross-tenant replication), Blob `sections.objectReplicationPolicies`/`sections.diagnosticSettings`, Defender evidence; coverage, subplan, scan and alert-response evidence supplied separately. | [ ] |

#### Cost Optimization — Azure Blob Storage

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| BLOB-11 | Choose account type, default/per-object tiers and redundancy using measured access, capacity and recovery requirements; model transaction/retrieval, minimum-retention/early-deletion, rehydration and transfer costs as well as stored bytes. | Selecting archive solely on capacity price or assuming account default tier describes every blob. | Storage `sections.show`; per-object tier/access inventory, pricing/cost model and retrieval-time requirements supplied separately. | [ ] |
| BLOB-12 | Use narrowly scoped lifecycle rules to tier or expire eligible current data, old versions and snapshots within retention/legal constraints; analyze high-overwrite growth without weakening required recovery protections. | Broad delete rules, archive transitions that break RTO, or disabling soft delete/versioning merely to reduce spend. | Storage `sections.managementPolicy`, Blob protection settings; approved retention matrix, matched-object inventory and lifecycle impact review. | [ ] |
| BLOB-13 | Monitor capacity/transaction/egress growth and optional-feature costs including inventory, change feed, versions, SFTP, encryption scopes and security; remove unused capabilities only after dependency/risk review and evaluate reservations for stable demand. | Idle paid features, unowned growth or commitments based on unverified forecasts. | Storage/Blob configuration; cost exports, utilization, budget/anomaly alerts, feature ownership and reservation analysis. | [ ] |

#### Operational Excellence — Azure Blob Storage

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| BLOB-14 | Manage accounts, containers, protection/network settings and lifecycle/replication policies as code with review, policy enforcement and drift detection; test high-impact delete/tier changes before broad rollout. | Portal-only changes or untested storage tasks that delete/retag/re-tier data at scale. | IaC/pipeline and Azure Policy evidence, baseline comparison; representative tests or Storage Actions mock-run results when that service is used. | [ ] |
| BLOB-15 | Enable relevant Blob service read/write/delete diagnostics with appropriate destination, access and retention; monitor availability, latency, throttling, capacity and authentication failures through owned alerts and tested notifications. | Collecting only account-level diagnostics or assuming configured log destinations prove events arrive. | Blob `sections.diagnosticSettings`; Storage insights/metrics, received log samples, alert/action-group definitions and notification tests supplied separately. | [ ] |
| BLOB-16 | Maintain an owned data inventory and recovery/retention runbooks; periodically reconcile age, tiers, versions, legal holds and replication destinations across regions against residency and lifecycle policy. | Assuming container enumeration is a per-blob inventory or retaining unmanaged replicas and expired data indefinitely. | Blob `sections.containers`/`sections.objectReplicationPolicies`, storage lifecycle configuration; blob inventory reports, review records and runbooks supplied separately. | [ ] |

#### Performance Efficiency — Azure Blob Storage

| ID | Review control | Avoid | Evidence | Status |
|---|---|---|---|---|
| BLOB-17 | Choose standard GPv2 or premium block blob accounts and plan supported capacity, transaction and ingress/egress limits from measured object sizes, concurrency and latency targets; load-test headroom and throttling behavior. | Premium accounts without measured need or application scale that exceeds account/partition limits. | Storage `sections.show` (kind/SKU); capacity forecast, Azure Monitor metrics and peak/soak test. | [ ] |
| BLOB-18 | Locate data near its clients within residency requirements; evaluate selective object replication or Front Door/CDN caching for distant readers with explicit consistency, authorization and invalidation behavior. | Replicating sensitive data outside approved regions or caching private content without an access design. | Storage locations, Blob `sections.objectReplicationPolicies`, edge configuration; measured latency and consistency/cache-security tests. | [ ] |
| BLOB-19 | Use supported Blob client libraries or appropriate transfer tools; tune bounded retries/backoff, connection reuse, parallelism, block size and transfer validation for representative data and bandwidth. | Custom unbounded retry loops, unlimited parallel transfers or fixed block-size advice applied to every workload. | Application/tool configuration and benchmark/fault/integrity results; management-plane collectors do not prove client behavior. | [ ] |
| BLOB-20 | Measure partition hot spots, listing/query costs and end-to-end versus server latency; optimize names/partitioning, batching and selective reads when evidence warrants, and prove archive retrieval latency meets the access objective. | Universal hash-prefix changes without measurement or placing immediately required data in archive. | Per-operation metrics/logs, naming/access design, per-object tiers and load/rehydration tests; manual evidence required. | [ ] |

## 8. Mandatory manual-validation register

The collector (`PSScripts\Invoke-CollectData.ps1`) cannot prove the following. Review every applicable item manually and retain dated evidence. Apply the same register to SQL and Blob workloads: database/Blob restore and failover, SQL grants/Blob data roles, key/SAS lifecycle, client resilience, query/transfer performance, alert delivery, deployment and cost governance all require supporting evidence. Application and service-specific clauses apply only where those components exist.

| ID | Manual validation | Required evidence | Status |
|---|---|---|---|
| MAN-01 | Confirm critical flows, dependencies, SLOs/SLIs, RTOs/RPOs, and accepted risks with business owners. | Approved business impact analysis, SLO document, dependency map, risk acceptance. | [ ] |
| MAN-02 | Exercise whole-workload restore and recovery for database, uploads, application/configuration, secrets, DNS, certificates, edge routing, and network policy. | Measured RTO/RPO report, defects, owners, remediation evidence. | [ ] |
| MAN-03 | Test zone, region, dependency, identity, DNS, network, deployment, and cache failure scenarios at an agreed cadence. | Game-day/fault-injection records and updated runbooks. | [ ] |
| MAN-04 | Review Entra tenant controls, Azure RBAC, PIM/JIT, MFA, Conditional Access, break-glass accounts, MySQL roles, and access-review outcomes. | Identity/RBAC exports, PIM settings, access-review records. | [ ] |
| MAN-05 | Verify application, runtime, dependency, package, container and IaC vulnerability/secret scanning, provenance, patching and ownership. | SBOM, scan reports, patch SLA, CI/CD configuration. | [ ] |
| MAN-06 | Exercise secret, certificate, key, and credential rotation, including dependent application validation and emergency access. | Rotation policy, expiry alerts, change records, successful test. | [ ] |
| MAN-07 | Test authentication, authorization, administrative-interface protection and security-alert response; include direct-origin bypass and WAF enforcement where used. | Negative access tests, identity/WAF logs, incident/tabletop evidence. | [ ] |
| MAN-08 | Verify IaC, peer review, policy checks, pipeline promotion, safe release, rollback, and drift detection. | Repository, pull requests, pipeline runs, drift reports. | [ ] |
| MAN-09 | Validate alert ownership, SLO/symptom coverage, action groups, dashboards, retention, runbooks, and notification tests. | Alert tests, dashboards, runbooks, on-call rota, postmortems. | [ ] |
| MAN-10 | Load, stress, soak, scalability, cache-invalidation, and failure-mode test critical flows in a production-like environment. | Versioned test scripts, reports, baselines, capacity conclusions. | [ ] |
| MAN-11 | Validate cost allocation, budgets, forecasts, anomaly alerts, cleanup, right-sizing, and commitment utilization. | Cost exports, budget alerts, monthly reviews, utilization reports. | [ ] |
| MAN-12 | Confirm application operational governance for approved components, staging validation, administrative access, privacy/consent, PII handling and outbound communication delivery where applicable. | Governance policy, access review, privacy assessment, delivery reports. | [ ] |

## 9. Scoring summary

Count each control ID once as `Pass`/`Fail`/`N/A`/`Not verified` in its section. Use the scoring rubric: score = `100 × Pass / (Pass + Fail)`; evidence coverage = `100 × (Pass + Fail) / (Total − N/A)`. Show score and coverage together. A zero denominator is `N/A`, not 0% or 100%. A high score over sparse evidence is not an assurance of a well-architected workload.

| Section | Total checks | Passed | Failed | N/A | Not verified | Score % | Coverage % |
|---|---|---|---|---|---|---|---|
| 1. Workload foundations and governance | 13 | | | | | | |
| 2. Reliability | 17 | | | | | | |
| 3. Security | 24 | | | | | | |
| 4. Cost Optimization | 14 | | | | | | |
| 5. Operational Excellence | 17 | | | | | | |
| 6. Performance Efficiency | 15 | | | | | | |
| 7. Resource-specific supplementary checklist | 85 | | | | | | |
| 8. Mandatory manual-validation register | 12 | | | | | | |
| **TOTAL** | **197** | | | | | | |

Section 7 contains the original 45 controls plus 20 Azure SQL Database and 20 Blob Storage controls. Within each new service supplement, Reliability has 4 controls, Security 6, Cost Optimization 3, Operational Excellence 3, and Performance Efficiency 4. Service-specific pillar views are alternate views of the same controls, not additional scored controls. Use the `five-pillars-v2` mapping in `Review/checklist.json`: combine core and mapped service-specific controls once per primary pillar, then take the unweighted mean of the five unrounded pillar ratios. Foundations and the manual register stay separate. If any pillar ratio is undefined, the corresponding headline measure is `n/a`. Preserve the original scoring model when displaying historical reports; do not silently migrate them. The total row counts all IDs; do not substitute its aggregate percentage for the rubric's headline.

## 10. Review completion record

| Field | Value |
|---|---|
| Workload/environment | |
| Subscription and resource group | |
| Review date | |
| Reviewers | |
| Business owner | |
| Security owner | |
| Data classification | |
| SLO / RTO / RPO | |
| Pass / Fail / N/A / Not verified totals | |
| Critical and high findings | |
| Accepted risks and approver | |
| Remediation backlog | |
| Next review date | |

## Microsoft guidance used

### Framework and security baseline

- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/what-is-well-architected-framework)
- [Azure Well-Architected Framework pillars](https://learn.microsoft.com/azure/well-architected/pillars)
- [Reliability design review checklist](https://learn.microsoft.com/azure/well-architected/reliability/checklist)
- [Security design review checklist](https://learn.microsoft.com/azure/well-architected/security/checklist)
- [Cost Optimization design review checklist](https://learn.microsoft.com/azure/well-architected/cost-optimization/checklist)
- [Operational Excellence design review checklist](https://learn.microsoft.com/azure/well-architected/operational-excellence/checklist)
- [Performance Efficiency design review checklist](https://learn.microsoft.com/azure/well-architected/performance-efficiency/checklist)
- [Introduction to the Microsoft cloud security benchmark](https://learn.microsoft.com/security/benchmark/azure/introduction)
- [Azure security baselines overview](https://learn.microsoft.com/security/benchmark/azure/security-baselines-overview)
- [Security policies and recommendations in Defender for Cloud](https://learn.microsoft.com/azure/defender-for-cloud/security-policy-concept)
- [Microsoft cloud security benchmark in Defender for Cloud](https://learn.microsoft.com/azure/defender-for-cloud/concept-regulatory-compliance)
- [Microsoft Defender for Cloud overview](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction)

### Service guidance and reference architectures

- [Well-Architected best practices for App Service](https://learn.microsoft.com/azure/well-architected/service-guides/app-service-web-apps)
- [Reliability in Azure App Service](https://learn.microsoft.com/azure/reliability/reliability-app-service)
- [App Service language support policy](https://learn.microsoft.com/azure/app-service/language-support-policy)
- [App Service networking features](https://learn.microsoft.com/azure/app-service/networking-features)
- [Well-Architected best practices for Azure Database for MySQL](https://learn.microsoft.com/azure/well-architected/service-guides/azure-database-for-mysql)
- [Well-Architected best practices for Azure SQL Database](https://learn.microsoft.com/en-us/azure/well-architected/service-guides/azure-sql-database)
- [Azure SQL Database automated backups and native recovery](https://learn.microsoft.com/azure/azure-sql/database/automated-backups-overview)
- [Azure SQL Database security baseline](https://learn.microsoft.com/security/benchmark/azure/baselines/sql-database-security-baseline)
- [Secure Azure Database for MySQL](https://learn.microsoft.com/azure/mysql/security/security-overview)
- [Azure Database for MySQL performance best practices](https://learn.microsoft.com/azure/mysql/flexible-server/concept-performance-best-practices)
- [Secure Azure Key Vault](https://learn.microsoft.com/azure/key-vault/general/secure-key-vault)
- [Azure Key Vault security baseline](https://learn.microsoft.com/security/benchmark/azure/baselines/key-vault-security-baseline)
- [Azure Cache for Redis retirement FAQ](https://learn.microsoft.com/azure/azure-cache-for-redis/retirement-faq)
- [Azure Cache for Redis connection resilience](https://learn.microsoft.com/azure/azure-cache-for-redis/cache-best-practices-connection)
- [Well-Architected best practices for Azure Front Door](https://learn.microsoft.com/azure/well-architected/service-guides/azure-front-door)
- [Secure Azure Front Door](https://learn.microsoft.com/azure/frontdoor/secure-front-door)
- [Well-Architected best practices for Blob Storage](https://learn.microsoft.com/azure/well-architected/service-guides/azure-blob-storage)
- [Secure an Azure Storage account](https://learn.microsoft.com/azure/storage/common/secure-storage)
- [Azure Storage security baseline](https://learn.microsoft.com/security/benchmark/azure/baselines/storage-security-baseline)
- [Reliability in Azure NAT Gateway](https://learn.microsoft.com/azure/reliability/reliability-nat-gateway)
- [Design virtual networks with NAT Gateway](https://learn.microsoft.com/azure/nat-gateway/nat-gateway-design)
- [Private Endpoint DNS integration](https://learn.microsoft.com/azure/private-link/private-endpoint-dns-integration)
- [Well-Architected best practices for Application Insights](https://learn.microsoft.com/azure/well-architected/service-guides/application-insights)
- [Well-Architected best practices for Log Analytics](https://learn.microsoft.com/azure/well-architected/service-guides/azure-log-analytics)
- [Azure Monitor Logs best practices](https://learn.microsoft.com/azure/azure-monitor/logs/best-practices-logs)
- [Azure Monitor daily cap guidance](https://learn.microsoft.com/azure/azure-monitor/logs/daily-cap)
- [Azure Communication Services security baseline](https://learn.microsoft.com/security/benchmark/azure/baselines/communication-services-security-baseline)
- [Azure App Service baseline architecture](https://learn.microsoft.com/azure/architecture/web-apps/app-service/architectures/baseline-zone-redundant)
- [Mission-critical App Service](https://learn.microsoft.com/azure/architecture/guide/networking/global-web-applications/mission-critical-app-service)
- [App Service security baseline](https://learn.microsoft.com/security/benchmark/azure/baselines/app-service-security-baseline)
