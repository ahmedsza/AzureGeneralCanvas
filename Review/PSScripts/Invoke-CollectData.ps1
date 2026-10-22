<#
.SYNOPSIS
Discovers resources in an Azure resource group and collects service-specific configuration evidence.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ResourceGroup,
    [string]$OutputDirectory = (Join-Path (Get-Location).Path ('azure-data-{0}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))),
    [string]$Subscription,
    [ValidateRange(1, 3600)][int]$CommandTimeoutSeconds = 120
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot 'Common-AzureCollector.ps1')
$PSDefaultParameterValues = @{} + $PSDefaultParameterValues
$PSDefaultParameterValues['Invoke-AzCommandJson:TimeoutSeconds'] = $CommandTimeoutSeconds
Test-AzCliPrerequisites

if (-not $Subscription) {
    $account = Invoke-AzCommandJson 'account.show' @('account', 'show') $null -Required
    $Subscription = [string]$account.data.id
}
if (-not (Test-Path $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null }

$resourceResult = Invoke-AzCommandJson 'resource.list' @('resource', 'list', '--resource-group', $ResourceGroup) $Subscription -Required
$resources = @($resourceResult.data | Where-Object { $null -ne $_ })
$inventory = New-CollectorDocument 'Microsoft.Resources/resourceGroups' $ResourceGroup $ResourceGroup $Subscription
Add-CollectorSection $inventory 'resourceGroup' (Invoke-AzCommandJson 'group.show' @('group', 'show', '--name', $ResourceGroup) $Subscription)
Add-CollectorSection $inventory 'resources' $resourceResult
Add-CollectorSection $inventory 'locks' (Invoke-AzCommandJson 'lock.list.resourceGroup' @('lock', 'list', '--resource-group', $ResourceGroup) $Subscription)
Add-CollectorSection $inventory 'roleAssignments' (Invoke-AzCommandJson 'role.assignment.list.resourceGroup' @('role', 'assignment', 'list', '--resource-group', $ResourceGroup) $Subscription)

$manifest = [ordered]@{
    metadata = [ordered]@{ schemaVersion = '4.0'; generatedAtUtc = (Get-Date).ToUniversalTime().ToString('o'); resourceGroup = $ResourceGroup; subscription = $Subscription }
    discovery = [ordered]@{ totalResourcesInGroup = $resources.Count; resourceTypes = @($resources | ForEach-Object { $_.type } | Sort-Object -Unique) }
    outputs = @()
    unsupportedResources = @()
    errors = @()
}

$pendingResources = [System.Collections.Generic.Queue[object]]::new()
$collectedResourceIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($resource in $resources) { $pendingResources.Enqueue($resource) }

function Invoke-ResourceCollector {
    param([string]$ScriptName, [hashtable]$Parameters)
    $scriptPath = Join-Path $PSScriptRoot $ScriptName
    if (-not (Test-Path $scriptPath)) {
        $manifest.errors += [ordered]@{ script = $ScriptName; message = 'Collector script is not present.' }
        Write-CollectorMessage -Level 'WARN' -Message ('Collector script is not present: {0}' -f $ScriptName)
        return
    }
    try {
        & $scriptPath @Parameters | ForEach-Object {
            $manifest.outputs += $_
            if ($_.PSObject.Properties['resourceId']) {
                [void]$collectedResourceIds.Add($_.resourceId)
            }
            if ($_.PSObject.Properties['discoveredResources']) {
                foreach ($child in $_.discoveredResources) { $pendingResources.Enqueue($child) }
            }
        }
    }
    catch {
        $manifest.errors += [ordered]@{ script = $ScriptName; resourceName = $Parameters['ResourceName']; message = $_.Exception.Message }
        Write-CollectorMessage -Level 'WARN' -Message ('Collector failed: {0} ({1})' -f $ScriptName, $_.Exception.Message)
    }
}

while ($pendingResources.Count -gt 0) {
    $resource = $pendingResources.Dequeue()
    if (-not $collectedResourceIds.Add([string]$resource.id)) { continue }
    $scriptName = Get-ResourceCollectorScriptName $resource.type
    if (-not $scriptName) {
        $kind = if ($resource.PSObject.Properties['kind']) { $resource.kind } else { $null }
        $manifest.unsupportedResources += [ordered]@{ name = $resource.name; type = $resource.type; id = $resource.id; kind = $kind }
        continue
    }
    $parameters = @{ ResourceGroup = $ResourceGroup; OutputDirectory = $OutputDirectory; Subscription = $Subscription; ResourceName = $resource.name; ResourceType = $resource.type }
    Invoke-ResourceCollector $scriptName $parameters
}

$inventoryFile = Join-Path $OutputDirectory 'resource-group-inventory.json'
Save-CollectorDocument $inventory $inventoryFile
$manifest.outputs += [pscustomobject]@{ resourceType = 'resourceGroupInventory'; name = $ResourceGroup; outputFile = $inventoryFile }

$resourceIdsFile = Join-Path $OutputDirectory 'discovered-resource-ids.json'
ConvertTo-Json -InputObject @($collectedResourceIds) | Set-Content -Path $resourceIdsFile -Encoding utf8
Invoke-ResourceCollector 'Get-DefenderForCloudData.ps1' @{ ResourceGroup = $ResourceGroup; OutputDirectory = $OutputDirectory; Subscription = $Subscription; ResourceIdsFile = $resourceIdsFile }

$manifestFile = Join-Path $OutputDirectory 'collection-manifest.json'
($manifest | ConvertTo-Json -Depth 100) | Set-Content -Path $manifestFile -Encoding utf8
$completionLevel = if ($manifest.errors.Count -gt 0) { 'WARN' } else { 'OK' }
Write-CollectorMessage -Level $completionLevel -Message ('Collection completed with {0} collector error(s). Manifest: {1}' -f $manifest.errors.Count, $manifestFile)

$outputDirectoryInfo = Get-Item -LiteralPath $OutputDirectory
$archiveName = '{0}-{1}-{2}.zip' -f $outputDirectoryInfo.Name, (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ'), ([guid]::NewGuid().ToString('N').Substring(0, 8))
$archiveFile = Join-Path $outputDirectoryInfo.Parent.FullName $archiveName
Compress-Archive -LiteralPath $outputDirectoryInfo.FullName -DestinationPath $archiveFile -CompressionLevel Optimal -ErrorAction Stop
Write-CollectorMessage -Level 'OK' -Message ('Collection archive: {0}' -f $archiveFile)

[pscustomobject]@{ outputDirectory = $outputDirectoryInfo.FullName; manifest = $manifestFile; zipFile = $archiveFile; discoveredResources = $resources.Count }