function Merge-Metadata {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$config,

        [Parameter(Position = 1, Mandatory = $false)]
        [object]$metadata = $null,

        [Parameter(Position = 2, Mandatory = $false)]
        [object[]]$tasks = @(),
    
        [Parameter(Position = 3, Mandatory = $false)]
        [string]$yamlPath = "$PSScriptRoot\..\..\pwshake.yaml"
    )
    process {
        if (-not $config['attributes']) {
            $config.attributes = @{}
        }

        if ($metadata) {
            if ($metadata -is [Hashtable]) {
                $config['attributes'] = Merge-Hashtables $config['attributes'] $metadata
            } elseif ($metadata -is [string]) {
                $string = ""
                if (Test-Path $metadata) {
                    if ((Split-Path $metadata -Leaf).EndsWith('.yaml') -or (Split-Path $metadata -Leaf).EndsWith('.json')) {
                        $metadata = Get-Content $metadata -Raw | ConvertFrom-Yaml
                    } elseif (!(Split-Path $metadata -Leaf).Contains('.')) {
                        foreach ($item in (Get-Content -Path $metadata)) {
                            if (-not $item.StartsWith('#')) {
                                $string += "$([regex]::Escape($item))`n"
                            }
                        }
                        $metadata = $string | ConvertFrom-StringData
                    }
                } elseif ($metadata -match '^{.+}$') {
                    $metadata = $metadata | ConvertFrom-Yaml
                } else {
                    foreach ($item in ($metadata -split '\n')) {
                        $string += "$([Regex]::Escape($item))`n"
                    }
                    $metadata = $string | ConvertFrom-StringData
                }
                
                $config['attributes'] = Merge-Hashtables $config['attributes'] $metadata
            } else {
                throw "`$metadata.GetType() = '$($metadata.GetType())' is unknown."
            }
        }

        if ($tasks) {
            $config.invoke_tasks = $tasks
        }
        
        $config.attributes.pwshake_path = (Split-Path $yamlPath -Resolve).ToString()
        $config.attributes.pwshake_log_path = (Join-Path -Path $config.attributes.pwshake_path -ChildPath "$((Resolve-Path $yamlPath | Get-Item).BaseName).log").ToString()
        $config.attributes.pwshake_module_path = (Split-Path $PSScriptRoot -Parent).ToString()
        $config.attributes.pwshake_version = (Invoke-Expression (Get-Content $PSScriptRoot\..\pwshake.psd1 -Raw)).ModuleVersion
        $config.attributes.work_dir = "$(Get-Location)"
        if (-not $config.scripts_directories) {
            $config.scripts_directories = @('.')
        }
        if (($config.scripts_directories.Count) -and (-not $config.scripts_directories.Contains('.'))) {
            $config.scripts_directories += '.'
        }
        if (Test-Path $config.attributes.pwshake_log_path) {
            Remove-Item -Path $config.attributes.pwshake_log_path -Force
        }

        return $config
    }
}
