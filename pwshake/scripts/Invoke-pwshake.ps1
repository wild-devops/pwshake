function Invoke-pwshake {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [string]$ConfigPath = "./pwshake.yaml",
    
        [Parameter(Position = 1, Mandatory = $false)]
        [Alias("RunLists", "Roles")]
        [object[]]$Tasks = @(),
    
        [Parameter(Position = 2, Mandatory = $false)]
        [object]$MetaData = $null,

        [Alias("WhatIf", "Noop")]
        [switch]$DryRun
    )
    process {
        $config = Load-Config -YamlPath $ConfigPath `
                    | Load-Resources `
                    | Merge-Includes -yamlPath $ConfigPath `
                    | Merge-Metadata -metadata $MetaData -tasks $Tasks -yamlPath $ConfigPath `
                    | Override-Attributes `
                    | Interpolate-Attributes

        Log-Verbose "PWSHAKE config:" $config
        Log-Verbose "$(ConvertTo-Yaml $config)" $config

        $arranged_tasks = Arrange-Tasks $config
        Log-Verbose "Arranged tasks:" $config
        Log-Verbose "$(ConvertTo-Yaml $arranged_tasks)" $config

        try {
            Push-Location $config.attributes.work_dir
            foreach ($task in $arranged_tasks) {
                Invoke-Task $task $config $dryRun
            }
        } finally {
            Pop-Location
        }
    }
}
