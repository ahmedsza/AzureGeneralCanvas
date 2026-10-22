BeforeAll {
    $collectorRoot = Split-Path $PSScriptRoot -Parent
    . (Join-Path $collectorRoot 'Common-AzureCollector.ps1')

    function az {
        param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)
        throw 'Tests must mock Azure CLI; live Azure calls are not allowed.'
    }

    function New-TestResource {
        param([string]$Type, [string]$Name)
        $parts = $Type -split '/'
        $names = $Name -split '/'
        $id = '/subscriptions/test-sub/resourceGroups/test-rg/providers/' + $parts[0]
        for ($i = 1; $i -lt $parts.Count; $i++) { $id += '/' + $parts[$i] + '/' + $names[$i - 1] }
        [pscustomobject]@{ id = $id; name = $Name; type = $Type }
    }

    function Invoke-TestCollection {
        param([switch]$Legacy, [switch]$DefaultSubscription)
        $entry = if ($Legacy) { 'Invoke-CollectWordPressPosture.ps1' } else { 'Invoke-CollectData.ps1' }
        $parameters = @{ ResourceGroup = 'test-rg'; OutputDirectory = (Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))) }
        if (-not $DefaultSubscription) { $parameters.Subscription = 'test-sub' }
        $result = & (Join-Path $collectorRoot $entry) @parameters
        [pscustomobject]@{
            result = $result
            manifest = Get-Content -Raw $result.manifest | ConvertFrom-Json
        }
    }
}

Describe 'Resource-group collection' {
    BeforeEach {
        $global:AzureCollectorTestState = @{
            resources = @()
            databases = @()
            pools = @()
            failureCommand = ''
            storageKind = 'StorageV2'
            calls = [System.Collections.Generic.List[object]]::new()
        }

        Mock az {
            param($Arguments)
            $global:LASTEXITCODE = 0
            $global:AzureCollectorTestState.calls.Add(@($Arguments))
            $optionIndex = [array]::IndexOf($Arguments, ($Arguments | Where-Object { $_ -like '--*' } | Select-Object -First 1))
            $command = $Arguments[0..($optionIndex - 1)] -join ' '
            if ($command -eq $global:AzureCollectorTestState.failureCommand) {
                $global:LASTEXITCODE = 1
                [Console]::Error.WriteLine('AuthorizationFailed: fixture access denied')
                return
            }
            function Get-Argument([string]$Flag) {
                $index = [array]::IndexOf($Arguments, $Flag)
                if ($index -ge 0) { return $Arguments[$index + 1] }
                return $null
            }
            $data = switch ($command) {
                'account show' { @{ id = 'test-sub' } }
                'resource list' { ,$global:AzureCollectorTestState.resources }
                'group show' { @{ name = 'test-rg' } }
                'sql server show' { New-TestResource 'Microsoft.Sql/servers' (Get-Argument '--name') }
                'sql db list' { ,$global:AzureCollectorTestState.databases }
                'sql elastic-pool list' { ,$global:AzureCollectorTestState.pools }
                'sql db show' {
                    $db = New-TestResource 'Microsoft.Sql/servers/databases' ("$(Get-Argument '--server')/$(Get-Argument '--name')")
                    $db | Add-Member -NotePropertyName administratorLoginPassword -NotePropertyValue 'fixture-secret'
                    $db
                }
                'sql elastic-pool show' { New-TestResource 'Microsoft.Sql/servers/elasticPools' ("$(Get-Argument '--server')/$(Get-Argument '--name')") }
                'sql db tde show' {
                    if ((Get-Argument '--name') -or -not (Get-Argument '--database')) { throw 'TDE requires --database, not --name.' }
                    @{ state = 'Enabled' }
                }
                'storage account show' {
                    $account = New-TestResource 'Microsoft.Storage/storageAccounts' (Get-Argument '--name')
                    $account | Add-Member -NotePropertyName kind -NotePropertyValue $global:AzureCollectorTestState.storageKind
                    $account
                }
                'storage account blob-service-properties show' {
                    $service = New-TestResource 'Microsoft.Storage/storageAccounts/blobServices' ("$(Get-Argument '--account-name')/default")
                    $service | Add-Member -NotePropertyName isVersioningEnabled -NotePropertyValue $true
                    $service
                }
                'storage container-rm list' {
                    if (-not (Get-Argument '--storage-account')) { throw 'Container management requires --storage-account.' }
                    ,@(@{ name = 'private-container'; publicAccess = 'None'; hasImmutabilityPolicy = $true; hasLegalHold = $false })
                }
                'webapp show' { New-TestResource 'Microsoft.Web/sites' (Get-Argument '--name') }
                'webapp deployment slot list' { ,@() }
                default {
                    if ($command -notmatch ' (show|list|get|list-links)$') { throw "Unexpected non-read command: $command" }
                    ,@()
                }
            }
            ConvertTo-Json -InputObject $data -Depth 30 -Compress
        }
    }

    AfterAll {
        Remove-Variable AzureCollectorTestState -Scope Global
    }

    It 'retains every existing resource type and routes the new SQL and Blob types case-insensitively' {
        $expected = @{
            'Microsoft.Web/serverfarms' = 'Get-AppServicePlanData.ps1'
            'Microsoft.Web/sites' = 'Get-AppServiceData.ps1'
            'Microsoft.DBforMySQL/flexibleServers' = 'Get-MySqlFlexibleServerData.ps1'
            'Microsoft.KeyVault/vaults' = 'Get-KeyVaultData.ps1'
            'Microsoft.Cache/Redis' = 'Get-ManagedRedisData.ps1'
            'Microsoft.Cache/redisEnterprise' = 'Get-ManagedRedisData.ps1'
            'Microsoft.Network/natGateways' = 'Get-NatGatewayData.ps1'
            'Microsoft.Cdn/profiles' = 'Get-FrontDoorData.ps1'
            'Microsoft.Cdn/CdnWebApplicationFirewallPolicies' = 'Get-FrontDoorData.ps1'
            'Microsoft.Network/frontDoorWebApplicationFirewallPolicies' = 'Get-FrontDoorData.ps1'
            'Microsoft.Storage/storageAccounts' = 'Get-StorageAccountData.ps1'
            'Microsoft.Communication/communicationServices' = 'Get-AzureCommunicationServicesData.ps1'
            'microsoft.insights/components' = 'Get-AppInsightsData.ps1'
            'Microsoft.OperationalInsights/workspaces' = 'Get-LogAnalyticsWorkspaceData.ps1'
            'Microsoft.Sql/servers' = 'Get-AzureSqlData.ps1'
            'Microsoft.Sql/servers/databases' = 'Get-AzureSqlData.ps1'
            'Microsoft.Sql/servers/elasticPools' = 'Get-AzureSqlData.ps1'
            'Microsoft.Storage/storageAccounts/blobServices' = 'Get-BlobStorageData.ps1'
        }
        foreach ($type in @('virtualNetworks', 'networkSecurityGroups', 'routeTables', 'privateEndpoints', 'privateDnsZones', 'publicIPAddresses')) {
            $expected["Microsoft.Network/$type"] = 'Get-NetworkTopologyData.ps1'
        }
        foreach ($type in $expected.Keys) {
            Get-ResourceCollectorScriptName $type.ToUpperInvariant() | Should -Be $expected[$type]
            Join-Path $collectorRoot $expected[$type] | Should -Exist
        }
        Get-ResourceCollectorScriptName 'Microsoft.Compute/virtualMachines' | Should -BeNullOrEmpty
    }

    It 'writes valid empty-group inventory, ID array, manifest, and archive' {
        $run = Invoke-TestCollection
        $run.result.discoveredResources | Should -Be 0
        $run.manifest.errors.Count | Should -Be 0
        $run.manifest.discovery.resourceTypes.Count | Should -Be 0
        (Get-Content -Raw (Join-Path $run.result.outputDirectory 'discovered-resource-ids.json')).Trim() | Should -Be '[]'
        $run.result.zipFile | Should -Exist
        $archive = [System.IO.Compression.ZipFile]::OpenRead($run.result.zipFile)
        try { @($archive.Entries | Where-Object Name -eq 'collection-manifest.json').Count | Should -Be 1 }
        finally { $archive.Dispose() }
    }

    It 'records unknown resources without requiring an optional kind property' {
        $global:AzureCollectorTestState.resources = @(New-TestResource 'Microsoft.Compute/virtualMachines' 'vm')
        $run = Invoke-TestCollection
        $run.manifest.unsupportedResources.Count | Should -Be 1
        $run.manifest.unsupportedResources[0].name | Should -Be 'vm'
        $run.manifest.errors.Count | Should -Be 0
    }

    It 'stops when required resource discovery fails rather than reporting an empty group' {
        $global:AzureCollectorTestState.failureCommand = 'resource list'
        { Invoke-TestCollection } | Should -Throw '*Required command failed for resource.list*'
    }

    It 'collects SQL children missing from resource list and avoids duplicate database collection' {
        $server = New-TestResource 'Microsoft.Sql/servers' 'sql1'
        $db = New-TestResource 'Microsoft.Sql/servers/databases' 'sql1/app'
        $pool = New-TestResource 'Microsoft.Sql/servers/elasticPools' 'sql1/pool'
        $inventoryDb = New-TestResource 'Microsoft.Sql/servers/databases' 'sql1/app'
        $inventoryDb.id = $inventoryDb.id.ToUpperInvariant()
        $global:AzureCollectorTestState.resources = @($inventoryDb, $server)
        $global:AzureCollectorTestState.databases = @($db, (New-TestResource 'Microsoft.Sql/servers/databases' 'sql1/second'))
        $global:AzureCollectorTestState.pools = @($pool)
        $run = Invoke-TestCollection
        $run.manifest.errors.Count | Should -Be 0
        $run.manifest.unsupportedResources.Count | Should -Be 0
        @($run.manifest.outputs | Where-Object resourceType -eq 'azureSqlDatabase').Count | Should -Be 2
        @($run.manifest.outputs | Where-Object resourceType -eq 'azureSqlElasticPool').Count | Should -Be 1
        @($global:AzureCollectorTestState.calls | Where-Object { ($_ | Select-Object -First 3) -join ' ' -eq 'sql db show' }).Count | Should -Be 2
        $doc = Get-Content -Raw (Join-Path $run.result.outputDirectory 'azure-sql-database-sql1-app.json') | ConvertFrom-Json
        $doc.sections.show.data.administratorLoginPassword | Should -Be 'SECRET_FOUND_REDACTED'
        $doc.sections.transparentDataEncryption.data.state | Should -Be 'Enabled'
        $doc.sections.shortTermRetention.success | Should -BeTrue
        $doc.sections.longTermRetention.success | Should -BeTrue
    }

    It 'retains optional command failures in SQL evidence' {
        $global:AzureCollectorTestState.resources = @(New-TestResource 'Microsoft.Sql/servers/databases' 'sql1/app')
        $global:AzureCollectorTestState.failureCommand = 'sql db audit-policy show'
        $run = Invoke-TestCollection
        $doc = Get-Content -Raw (Join-Path $run.result.outputDirectory 'azure-sql-database-sql1-app.json') | ConvertFrom-Json
        $doc.sections.auditing.success | Should -BeFalse
        $doc.sections.auditing.exitCode | Should -Be 1
        $doc.sections.longTermRetention.success | Should -BeTrue
    }

    It 'continues after a required SQL failure and identifies the resource in the manifest' {
        $global:AzureCollectorTestState.resources = @(
            (New-TestResource 'Microsoft.Sql/servers' 'denied'),
            (New-TestResource 'Microsoft.Storage/storageAccounts' 'storage1')
        )
        $global:AzureCollectorTestState.failureCommand = 'sql server show'
        $run = Invoke-TestCollection
        $run.manifest.errors.Count | Should -Be 1
        $run.manifest.errors[0].resourceName | Should -Be 'denied'
        @($run.manifest.outputs | Where-Object resourceType -eq 'blobStorage').Count | Should -Be 1
    }

    It 'collects Blob configuration once even when the child is already in the RG inventory' {
        $global:AzureCollectorTestState.resources = @(
            (New-TestResource 'Microsoft.Storage/storageAccounts/blobServices' 'storage1/default'),
            (New-TestResource 'Microsoft.Storage/storageAccounts' 'storage1')
        )
        $run = Invoke-TestCollection
        $run.manifest.errors.Count | Should -Be 0
        @($run.manifest.outputs | Where-Object resourceType -eq 'storageAccount').Count | Should -Be 1
        @($run.manifest.outputs | Where-Object resourceType -eq 'blobStorage').Count | Should -Be 1
        $doc = Get-Content -Raw (Join-Path $run.result.outputDirectory 'blob-storage-storage1.json') | ConvertFrom-Json
        $doc.sections.show.data.isVersioningEnabled | Should -BeTrue
        $doc.sections.containers.data.publicAccess | Should -Be 'None'
        @($global:AzureCollectorTestState.calls | Where-Object { ($_ -join ' ') -match 'list-keys|generate-sas|storage blob |storage container ' }).Count | Should -Be 0
    }

    It 'preserves Blob failures as evidence without using a data-plane fallback' {
        $global:AzureCollectorTestState.resources = @(New-TestResource 'Microsoft.Storage/storageAccounts' 'storage1')
        $global:AzureCollectorTestState.failureCommand = 'storage container-rm list'
        $run = Invoke-TestCollection
        $doc = Get-Content -Raw (Join-Path $run.result.outputDirectory 'blob-storage-storage1.json') | ConvertFrom-Json
        $doc.sections.containers.success | Should -BeFalse
        $doc.sections.show.success | Should -BeTrue
    }

    It 'still collects container metadata when Blob service properties are unavailable' {
        $global:AzureCollectorTestState.resources = @(New-TestResource 'Microsoft.Storage/storageAccounts' 'storage1')
        $global:AzureCollectorTestState.failureCommand = 'storage account blob-service-properties show'
        $run = Invoke-TestCollection
        $doc = Get-Content -Raw (Join-Path $run.result.outputDirectory 'blob-storage-storage1.json') | ConvertFrom-Json
        $run.manifest.errors.Count | Should -Be 0
        $doc.sections.show.success | Should -BeFalse
        $doc.sections.containers.success | Should -BeTrue
    }

    It 'does not schedule Blob collection for file-only storage accounts' {
        $global:AzureCollectorTestState.resources = @(New-TestResource 'Microsoft.Storage/storageAccounts' 'files1')
        $global:AzureCollectorTestState.storageKind = 'FileStorage'
        $run = Invoke-TestCollection
        @($run.manifest.outputs | Where-Object resourceType -eq 'blobStorage').Count | Should -Be 0
    }

    It 'keeps App Service collection working for apps with no slots' {
        $global:AzureCollectorTestState.resources = @(New-TestResource 'Microsoft.Web/sites' 'app1')
        $run = Invoke-TestCollection
        $run.manifest.errors.Count | Should -Be 0
        @($run.manifest.outputs | Where-Object resourceType -eq 'appService').Count | Should -Be 1
    }

    It 'passes the selected subscription to every Azure command' {
        $global:AzureCollectorTestState.resources = @(New-TestResource 'Microsoft.Sql/servers' 'sql1')
        $null = Invoke-TestCollection
        foreach ($call in $global:AzureCollectorTestState.calls) {
            $index = [array]::IndexOf($call, '--subscription')
            $index | Should -BeGreaterThan -1
            $call[$index + 1] | Should -Be 'test-sub'
        }
    }

    It 'supports the legacy entry point and resolves the current subscription when omitted' {
        $run = Invoke-TestCollection -Legacy -DefaultSubscription
        $run.manifest.metadata.subscription | Should -Be 'test-sub'
        $run.manifest.errors.Count | Should -Be 0
        $run.result.zipFile | Should -Exist
    }
}
