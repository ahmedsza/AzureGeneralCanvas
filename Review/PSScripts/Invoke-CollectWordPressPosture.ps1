<#
.SYNOPSIS
Compatibility entry point. Use Invoke-CollectData.ps1 for resource-group collection.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ResourceGroup,
    [string]$OutputDirectory = (Join-Path (Get-Location).Path ('wordpress-posture-{0}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))),
    [string]$Subscription,
    [ValidateRange(1, 3600)][int]$CommandTimeoutSeconds = 120
)

& (Join-Path $PSScriptRoot 'Invoke-CollectData.ps1') -ResourceGroup $ResourceGroup -OutputDirectory $OutputDirectory -Subscription $Subscription -CommandTimeoutSeconds $CommandTimeoutSeconds
