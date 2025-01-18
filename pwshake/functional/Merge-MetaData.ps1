function Merge-Metadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [hashtable]${@context},
        [scriptblock]${@next}=${@next-stub}
    )
    process {
        [hashtable]$config = ${@context}.config
        [object]$metadata  = ${global:actor-context}.arguments.MetaData,
        [object[]]$tasks   = ${global:actor-context}.arguments.Tasks

        if (-not $config['attributes']) {
            $config.attributes = @{}
        }

        return &${@next}(@{config=$config}) #!!! REMOVE THIS !!!

        if ($metadata) {
            @{'$metadata'=$metadata} | f-cty | f-wh-m
            if ($metadata -is [object[]] -and !$metadata.Length) {
                return &${@next}(@{config=$config})
            }
            elseif ($metadata -is [hashtable]) {
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
                    $metadata = $metadata | f-cfy
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

        return &${@next}(@{config=$config})
    }
}
