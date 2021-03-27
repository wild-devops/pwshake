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
        [ValidateSet('Error', 'Warning', 'Minimal', 'Information', 'Verbose', 'Debug', 'Normal', 'Default', 'Silent', 'Quiet')]
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
        $context = @{json_sb=(New-Object 'Text.StringBuilder');thrown=$false}
        $context.Remove('invocations')
        ${global:pwshake-context}.invocations.Push(@{
                arguments = ($arguments + @{Tasks = $Tasks; WorkDir = "$(Get-Location)" })
                # early loading (before stages invocation) is required for base settings of logging etc.
                config    = (Load-Config @arguments)
                context   = $context
            })

        try {
            try {
                $caption = "PWSHAKE arguments:"
                $caption | f-log-verb
                "$(ConvertTo-Yaml (Peek-Invocation).arguments)" | f-log-verb

                foreach ($stage in ${global:pwshake-context}.stages) {
                    "Invoke-pwshake:`$stage`:{$stage}" | f-log-dbg
                    (Peek-Invocation).config = Invoke-Expression "(Peek-Config) | $stage"
                }

                "Invoke-pwshake:stagesInvoked:`$config:`n$(ConvertTo-Yaml (Peek-Config))" | f-log-dbg

                $caption = "PWSHAKE config:"
                $caption | f-log-verb
                "$(ConvertTo-Yaml (Peek-Config))" | f-log-verb
            }
            finally {
                if ((Peek-Config).attributes.pwshake_log_to_json) {
                    $context.json_sb.ToString() | f-json | Add-Content -Path "$((Peek-Config).attributes.pwshake_log_path).json" -Encoding UTF8
                }
            }

            $arranged_tasks = (Peek-Config).invoke_tasks | Arrange-Tasks
            "Invoke-pwshake:`$arranged_tasks:`n$(ConvertTo-Yaml $arranged_tasks)" | f-log-dbg

            Push-Location (Peek-Config).attributes.work_dir
            $arranged_tasks | Invoke-Task
            
        } catch {
            if (-not (Peek-Context).caught) {
                # if it was not thrown in execution context, it should be logged
                $_ | f-log-err
            }
            throw $_
        } finally {
            Pop-Location
            if ((Peek-Config).attributes.pwshake_log_to_json) {
                (Peek-Context).json_sb.ToString() | f-json | Add-Content -Path "$((Peek-Config).attributes.pwshake_log_path).json" -Encoding UTF8
            }
            "Invoke-pwshake:finally:`${global:pwshake-context}.invocations.Count:{$(${global:pwshake-context}.invocations.Count)}" | f-log-dbg
            ${global:pwshake-context}.invocations.Pop() | Out-Null
        }
    }
}

function Peek-Invocation {
    return ${global:pwshake-context}.invocations.Peek()
}

function Peek-Context{
    return (Peek-Invocation).context
}

function Peek-Config {
    return (Peek-Invocation).config
}

function Peek-Verbosity {
    return [PWSHAKE.VerbosityLevel](Peek-Invocation).config.attributes.pwshake_verbosity
}
