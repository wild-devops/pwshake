function Invoke-Task {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$task,

    [Parameter(Mandatory = $false)]
    [hashtable]$config = (Peek-Config)
  )
  process {
    $caption = "Invoke task: $($task.name)"

    try {
      $caption | f-teamcity-o | f-log-info

      if (-not (Invoke-Expression $task.when)) {
        "`t`tBypassed because of: [$($task.when)] = $(Invoke-Expression $task.when)" | f-log-info
        return;
      }

      Push-Location (Build-Path "$($task.work_dir)" $config)

      foreach ($step in $task.steps) {
        (Peek-Data).caught = $false
        $step | Invoke-Step -work_dir $task.work_dir
      }
    } catch {
      if (-not (Peek-Data).caught) {
        # if it was not caught in execution context, it should be logged
        $_ | f-log-err
      }
      if ($task.on_error -eq 'throw') {
        (Peek-Data).caught = $true
        throw $_
      }
    }
    finally {
      Pop-Location
      if ($config.attributes.pwshake_log_to_json) {
        sb-to-string | f-json | Add-Content -Path "$(Peek-LogPath).json" -Encoding UTF8
        (Peek-Data).json_sb.Clear() | Out-Null
      }
      $caption | f-teamcity-c | f-log-info
    }
  }
}
