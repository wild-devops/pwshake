function Invoke-pwshake {
    [CmdletBinding()]
    param (
        [Alias("Path","File","ConfigFile")]
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ConfigPath = (Resolve-Path "${PWD}\pwshake.yaml"),

        [Parameter(Position = 1, Mandatory = $false)]
        [Alias("RunLists", "Roles")]
        [object[]]$Tasks = @(),

        [Alias("Attributes")]
        [Parameter(Position = 2, Mandatory = $false)]
        [object]$MetaData = $null,

        [Alias("WhatIf", "Noop")]
        [switch]$DryRun,

        [Alias("LogLevel")]
        [ValidateSet('Error', 'Warning', 'Minimal', 'Information', 'Verbose', 'Debug', 'Normal', 'Default')]
        [Parameter(Mandatory = $false)]
        [string]$Verbosity = 'Default'

    )
    process {
        $arguments = @{
            ConfigPath  = $ConfigPath
            MetaData    = $MetaData
            Verbosity   = $Verbosity
            DryRun      = [bool]$DryRun
        }
        $context = ${global:pwshake-context}.Clone() + @{json_sb=(New-Object 'Text.StringBuilder')}
        $context.Remove('invocations')
        ${global:pwshake-context}.invocations.Push(@{
                arguments = ($arguments + @{Tasks = $Tasks; WorkDir = "$(Get-Location)" })
                # early loading (before stages invocation) is required for base settings of logging etc.
                config    = (Load-Config @arguments)
                context = $context
            })

        try {
            try {
                $caption = "PWSHAKE arguments:"
                $caption | Log-Verbose 6>&1 | tee-sb | Write-Host
                "$(ConvertTo-Yaml (Peek-Invocation).arguments)" | Log-Verbose 6>&1 | tee-sb | Write-Host

                foreach ($stage in ${global:pwshake-context}.stages) {
                    "Invoke-pwshake:`$stage`:{$stage}" | f-dbg
                    (Peek-Invocation).config = Invoke-Expression "(Peek-Config) | $stage"
                }

                "Invoke-pwshake:stagesInvoked:`$config:`n$(ConvertTo-Yaml (Peek-Config))" | f-dbg

                $caption = "PWSHAKE config:"
                $caption | Log-Verbose 6>&1 | tee-sb | Write-Host
                "$(ConvertTo-Yaml (Peek-Config))" | Log-Verbose 6>&1 | tee-sb | Write-Host
            }
            finally {
                if ((Peek-Config).attributes.pwshake_log_to_json) {
                    $context.json_sb.ToString() | f-json | Add-Content -Path "$((Peek-Config).attributes.pwshake_log_path).json" -Encoding UTF8
                }
            }

            $arranged_tasks = Arrange-Tasks (Peek-Config)
            "Invoke-pwshake:`$arranged_tasks:`n$(ConvertTo-Yaml $arranged_tasks)" | f-dbg

            Push-Location (Peek-Config).attributes.work_dir
            foreach ($task in $arranged_tasks) {
                Invoke-Task $task
            }
        }
        finally {
            Pop-Location
            "Invoke-pwshake:finally:`${global:pwshake-context}.invocations.Count:{$(${global:pwshake-context}.invocations.Count)}" | f-dbg
            ${global:pwshake-context}.invocations.Pop() | Out-Null
        }
    }
}

function global:Peek-Invocation {
    return ${global:pwshake-context}.invocations.Peek()
}

function global:Peek-Config {
    return (Peek-Invocation).config
}

function global:Peek-Context{
    return (Peek-Invocation).context
}
