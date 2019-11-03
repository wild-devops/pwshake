function Invoke-Task {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$task,

        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$config,

        [Parameter(Position = 2, Mandatory = $false)]
        [bool]$dryRun = $false
    )
    process {
        Log-Verbose "Invoke task: $($task.name)" $config

        if (-not (Invoke-Expression $task.when)) {
            Log-Verbose "`t`tBypassed because of: [$($task.when)] = $(Invoke-Expression $task.when)" $config
            continue;
        }
        try {
            Push-Location (Normalize-Path "$($task.work_dir)" $config)

            foreach ($step in $task.steps) {
                if (-not $dryRun) {
                    Invoke-Step $config $step $task.work_dir
                } else {
                    Log-Verbose "`t`tBypassed because of -DryRun:$dryRun" $config
                }
            }
        } finally {
            Pop-Location
        }
    }
}
