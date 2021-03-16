function Merge-Metadata {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$config,

        [Parameter(Position = 1, Mandatory = $false)]
        [object]$metadata = (Peek-Invocation).arguments.MetaData,

        [Parameter(Position = 2, Mandatory = $false)]
        [object[]]$tasks = (Peek-Invocation).arguments.Tasks,

        [Parameter(Position = 3, Mandatory = $false)]
        [string]$yamlPath = (Peek-Invocation).arguments.ConfigPath
    )
    process {
        if (-not $config['attributes']) {
            $config.attributes = @{}
        }

        if ($metadata) {
            if ($metadata -is [Hashtable]) {
                $config['attributes'] = Merge-Hashtables $config['attributes'] $metadata
            }
            elseif ($metadata -is [string]) {
                $string = ""
                if (Test-Path $metadata) {
                    if ((Split-Path $metadata -Leaf).EndsWith('.yaml') -or (Split-Path $metadata -Leaf).EndsWith('.json')) {
                        $metadata = $metadata | Build-FromYaml
                    }
                    elseif (!(Split-Path $metadata -Leaf).Contains('.')) {
                        foreach ($item in (Get-Content -Path $metadata)) {
                            if (-not $item.StartsWith('#')) {
                                $string += "$([regex]::Escape($item))`n"
                            }
                        }
                        $metadata = $string | ConvertFrom-StringData
                    }
                }
                elseif ($metadata -match '^{.+}$') {
                    $metadata = $metadata | ConvertFrom-Yaml
                }
                else {
                    foreach ($item in ($metadata -split '\n')) {
                        $string += "$([Regex]::Escape($item))`n"
                    }
                    $metadata = $string | ConvertFrom-StringData
                }

                $config['attributes'] = Merge-Hashtables $config['attributes'] $metadata
            }
            else {
                throw "`$metadata.GetType() = '$($metadata.GetType())' is unknown."
            }
        }

        if ($tasks) {
            $config.invoke_tasks = $tasks
        }

        return $config
    }
}
