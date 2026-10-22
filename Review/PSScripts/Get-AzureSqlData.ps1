<#
.SYNOPSIS
Collects Azure SQL logical server, database, and elastic pool configuration (not database contents).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceName,
    [Parameter(Mandatory)][string]$ResourceType,
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [string]$Subscription
)

. (Join-Path $PSScriptRoot 'Common-AzureCollector.ps1')
$doc = New-CollectorDocument $ResourceType $ResourceName $ResourceGroup $Subscription
$nameParts = $ResourceName -split '/'
$serverName = $nameParts[0]
$scopeArguments = @('--resource-group', $ResourceGroup)
$children = @()

switch ($ResourceType) {
    'Microsoft.Sql/servers' {
        $show = Invoke-AzCommandJson 'sql.server.show' (@('sql', 'server', 'show', '--name', $serverName) + $scopeArguments) $Subscription -Required
        Add-CollectorSection $doc 'show' $show
        foreach ($item in @(
            @('firewallRules', 'firewall-rule', 'list', '--server'),
            @('virtualNetworkRules', 'vnet-rule', 'list', '--server'),
            @('entraAdministrators', 'ad-admin', 'list', '--server'),
            @('entraOnlyAuthentication', 'ad-only-auth', 'get', '--name'),
            @('auditing', 'audit-policy', 'show', '--name'),
            @('encryptionProtector', 'tde-key', 'show', '--server')
        )) {
            Add-CollectorSection $doc $item[0] (Invoke-AzCommandJson ('sql.server.' + $item[0]) (@('sql', 'server', $item[1], $item[2], $item[3], $serverName) + $scopeArguments) $Subscription)
        }
        Add-CollectorSection $doc 'failoverGroups' (Invoke-AzCommandJson 'sql.failover-group.list' (@('sql', 'failover-group', 'list', '--server', $serverName) + $scopeArguments) $Subscription)
        foreach ($item in @(
            @('databases', 'db', 'Microsoft.Sql/servers/databases'),
            @('elasticPools', 'elastic-pool', 'Microsoft.Sql/servers/elasticPools')
        )) {
            $list = Invoke-AzCommandJson ('sql.' + $item[1] + '.list') (@('sql', $item[1], 'list', '--server', $serverName) + $scopeArguments) $Subscription
            Add-CollectorSection $doc $item[0] $list
            if ($list.success) {
                foreach ($child in @($list.data | Where-Object { $null -ne $_ })) {
                    $children += [pscustomobject]@{
                        id = $child.id
                        name = '{0}/{1}' -f $serverName, ($child.name -split '/')[-1]
                        type = $item[2]
                    }
                }
            }
        }
        $outputType = 'azureSqlServer'
        $filePrefix = 'azure-sql-server'
    }
    'Microsoft.Sql/servers/databases' {
        if ($nameParts.Count -ne 2) { throw 'SQL database ResourceName must be server/database.' }
        $dbArguments = @('--server', $serverName, '--name', $nameParts[1]) + $scopeArguments
        $show = Invoke-AzCommandJson 'sql.db.show' (@('sql', 'db', 'show') + $dbArguments) $Subscription -Required
        Add-CollectorSection $doc 'show' $show
        Add-CollectorSection $doc 'transparentDataEncryption' (Invoke-AzCommandJson 'sql.db.tde.show' (@('sql', 'db', 'tde', 'show', '--server', $serverName, '--database', $nameParts[1]) + $scopeArguments) $Subscription)
        foreach ($item in @(
            @('auditing', 'audit-policy'),
            @('shortTermRetention', 'str-policy'),
            @('longTermRetention', 'ltr-policy')
        )) {
            Add-CollectorSection $doc $item[0] (Invoke-AzCommandJson ('sql.db.' + $item[1]) (@('sql', 'db', $item[1], 'show') + $dbArguments) $Subscription)
        }
        Add-CollectorSection $doc 'replicationLinks' (Invoke-AzCommandJson 'sql.db.replica.list-links' (@('sql', 'db', 'replica', 'list-links') + $dbArguments) $Subscription)
        $outputType = 'azureSqlDatabase'
        $filePrefix = 'azure-sql-database'
    }
    'Microsoft.Sql/servers/elasticPools' {
        if ($nameParts.Count -ne 2) { throw 'SQL elastic pool ResourceName must be server/pool.' }
        $show = Invoke-AzCommandJson 'sql.elastic-pool.show' (@('sql', 'elastic-pool', 'show', '--server', $serverName, '--name', $nameParts[1]) + $scopeArguments) $Subscription -Required
        Add-CollectorSection $doc 'show' $show
        $outputType = 'azureSqlElasticPool'
        $filePrefix = 'azure-sql-elastic-pool'
    }
    default { throw ('Unsupported Azure SQL resource type: {0}' -f $ResourceType) }
}

Add-StandardResourceEvidence $doc $show.data.id $Subscription
$file = Join-Path $OutputDirectory ('{0}-{1}.json' -f $filePrefix, (ConvertTo-CollectorSafeFileName $ResourceName))
Save-CollectorDocument $doc $file
[pscustomobject]@{
    resourceType = $outputType
    resourceId = $show.data.id
    name = $ResourceName
    outputFile = $file
    discoveredResources = $children
}
