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
        $throw = $true

        try {
            $caption | Log-Information 6>&1 | tee-sb | Write-Host

            if (-not (Invoke-Expression $task.when)) {
                "`t`tBypassed because of: [$($task.when)] = $(Invoke-Expression $task.when)" `
                | Log-Information 6>&1 | tee-sb | Out-Null
                continue;
            }

            Push-Location (Build-Path "$($task.work_dir)" $config)

            foreach ($step in $task.steps) {
                $step = Build-Item $step
                $throw = ((Coalesce $step.on_error, 'throw') -eq 'throw')
                $step | Invoke-Step -work_dir $task.work_dir
            }
        }
        catch {
            $_ | f-error | tee-sb | Out-Null
            Log-Error $_ -Rethrow $throw
        }
        finally {
            Pop-Location
            if ($config.attributes.pwshake_log_to_json) {
                (Peek-Context).json_sb.ToString() | f-json | Add-Content -Path "$($config.attributes.pwshake_log_path).json" -Encoding UTF8
            }
        }
    }
}
