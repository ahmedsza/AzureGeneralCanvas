<#
.SYNOPSIS
Collects Blob service and container configuration using management-plane APIs only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceName,
    [string]$ResourceType = 'Microsoft.Storage/storageAccounts/blobServices',
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [string]$Subscription
)

. (Join-Path $PSScriptRoot 'Common-AzureCollector.ps1')
$accountName = ($ResourceName -split '/')[0]
$doc = New-CollectorDocument 'Microsoft.Storage/storageAccounts/blobServices' "$accountName/default" $ResourceGroup $Subscription
$service = Invoke-AzCommandJson 'storage.blobService.show' @('storage', 'account', 'blob-service-properties', 'show', '--account-name', $accountName, '--resource-group', $ResourceGroup) $Subscription
Add-CollectorSection $doc 'show' $service
Add-CollectorSection $doc 'containers' (Invoke-AzCommandJson 'storage.container-rm.list' @('storage', 'container-rm', 'list', '--storage-account', $accountName, '--resource-group', $ResourceGroup) $Subscription)
Add-CollectorSection $doc 'objectReplicationPolicies' (Invoke-AzCommandJson 'storage.account.or-policy.list' @('storage', 'account', 'or-policy', 'list', '--account-name', $accountName, '--resource-group', $ResourceGroup) $Subscription)
if ($service.success -and $service.data.id) {
    Add-StandardResourceEvidence $doc $service.data.id $Subscription
}
$file = Join-Path $OutputDirectory ('blob-storage-{0}.json' -f (ConvertTo-CollectorSafeFileName $accountName))
Save-CollectorDocument $doc $file
$result = [pscustomobject]@{ resourceType = 'blobStorage'; name = "$accountName/default"; outputFile = $file }
if ($service.success -and $service.data.id) { $result | Add-Member -NotePropertyName resourceId -NotePropertyValue $service.data.id }
$result
