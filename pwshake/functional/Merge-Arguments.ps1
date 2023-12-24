function Merge-Arguments {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$config,

        [Parameter(Position = 1, Mandatory = $false)]
        [hashtable]$arguments = (Peek-Invocation).arguments
    )
    process {
        $ErrorActionPreference = "Stop"

        if (-not $config['attributes']) {
            $config.attributes = @{}
        }

        filter f-cfsd {
            $string = ""
            foreach ($item in $_) {
                if (-not $item.StartsWith('#')) {
                    $string += "$([regex]::Escape($item.Trim("`r")))`n"
                }
            }
            return $string | ConvertFrom-StringData
        }

        $metadata = (Coalesce $arguments.MetaData,  $arguments.Attributes, @{})
        if ($metadata) {
            if ($metadata -is [hashtable]) {
                $config['attributes'] = Merge-Hashtables $config['attributes'] $metadata
            }
            elseif ($metadata -is [string]) {
                if ($metadata -match '^{.+}$') {
                    $metadata = $metadata | ConvertFrom-Yaml
                }
                elseif ($metadata -match '\S+=\S+') {
                    $metadata = ,($metadata -split "`n") | f-cfsd
                }
                elseif (Test-Path $metadata) {
                    if ((Split-Path $metadata -Leaf).EndsWith('.yaml') -or (Split-Path $metadata -Leaf).EndsWith('.json')) {
                        $metadata = $metadata | Build-FromYaml
                    }
                    elseif (-not (Split-Path $metadata -Leaf).Contains('.')) {
                        $metadata = ,(Get-Content -Path $metadata) | f-cfsd
                    }
                }
                else {
                    throw "File '$metadata' does not exist."
                }

                $config['attributes'] = Merge-Hashtables $config['attributes'] $metadata
            }
            else {
                throw "Unknown type of -MetaData argument: '$($metadata.GetType())'."
            }

            $json = $config | f-ctj-c
            $metadata.Keys | f-null | ForEach-Object {
                "Merge-Arguments:Override: key: '$_', value: '$($metadata.$($_))'" | f-log-dbg
                $json = $json.Replace("{{$_}}", ($metadata.$($_) | f-escape-json))
            }
            $config = ConvertFrom-Yaml $json
            "Merge-Arguments:Substituted:`$config:`n$($config | cty)" | f-log-dbg
        }

        $tasks = (Coalesce $arguments.Tasks,  $arguments.RunLists,  $arguments.Roles, @())
        if ($tasks) {
            $config.invoke_tasks = @() + $tasks
        }

        "Merge-Arguments:Out:`$config:`n$($config | cty)" | f-log-dbg
        return $config
    }
}
