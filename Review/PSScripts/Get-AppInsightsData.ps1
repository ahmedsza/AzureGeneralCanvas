[CmdletBinding()]
param(
    [string]$ResourceName,
    [string]$ResourceType,
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [string]$Subscription
)

. (Join-Path $PSScriptRoot 'Common-AzureCollector.ps1')
$doc = New-CollectorDocument $ResourceType $ResourceName $ResourceGroup $Subscription
$app = Invoke-AzCommandJson 'app-insights.resource.show' @(
    'resource', 'show', '--resource-type', 'Microsoft.Insights/components',
    '--name', $ResourceName, '--resource-group', $ResourceGroup, '--api-version', '2020-02-02'
) $Subscription -Required
Add-CollectorSection $doc 'show' $app
if ($app.data.id) { Add-StandardResourceEvidence $doc $app.data.id $Subscription }
$file = Join-Path $OutputDirectory ('app-insights-{0}.json' -f (ConvertTo-CollectorSafeFileName $ResourceName))
Save-CollectorDocument $doc $file
[pscustomobject]@{ resourceType = 'appInsights'; name = $ResourceName; outputFile = $file }