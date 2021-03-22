function Invoke-Task {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$task,

        [Parameter(Position = 1, Mandatory = $false)]
        [hashtable]$config = (Coalesce (Peek-Config), @{})
    )
    process {
        $caption = "Invoke task: $($task.name)"

        try {
            $caption | f-log-info

            if (-not (Invoke-Expression $task.when)) {
                "`t`tBypassed because of: [$($task.when)] = $(Invoke-Expression $task.when)" | f-log-info
                continue;
            }

            Push-Location (Build-Path "$($task.work_dir)" $config)

            foreach ($step in $task.steps) {
                (Peek-Context).thrown = $false
                $step | Invoke-Step -work_dir $task.work_dir
            }
        } catch {
            if (-not (Peek-Context).thrown) {
                # if it was not thrown in execution context, it should be logged
                $_ | f-log-err
            }
            if ($task.on_error -eq 'throw') {
                throw $_
            }
        }
        finally {
            Pop-Location
            if ($config.attributes.pwshake_log_to_json) {
                (Peek-Context).json_sb.ToString() | f-json | Add-Content -Path "$($config.attributes.pwshake_log_path).json" -Encoding UTF8
                (Peek-Context).json_sb.Clear() | Out-Null
            }
        }
    }
}
