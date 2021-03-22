function Invoke-Step {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [object]$step,

    [Parameter(Position = 1, Mandatory = $false)]
    [hashtable]$config = (Coalesce (Peek-Config), @{}),

    [Parameter(Position = 2, Mandatory = $false)]
    [string]$work_dir = ''
  )
  process {
    $ErrorActionPreference = 'Continue'

    try {
      "Invoke-Step:In:$(@{'$_'=$_} | ConvertTo-Yaml)" | f-log-dbg
      $step = $step | Build-Step
      "Invoke-Step:Build-Step:$(@{'$step'=$step} | ConvertTo-Yaml)" | f-log-dbg

      if ($step['$context'].template_key) {
        # add alias to simplify templates definition
        New-Variable -Name $step['$context'].template_key -Value $step -Force
      }

      if ($work_dir) {
        # Since actual execution is performed in the $step that can contain it's own .work_dir property
        # override it only if the $step.work_dir is empty
        if (-not $step.work_dir) {
          $step.work_dir = $work_dir
        }
      }

      ${global:pwshake-context}.hooks['invoke-step'].onEnter | ForEach-Object {
        "Invoke-Step:try:{$_}" | f-log-dbg; Invoke-Expression $_
      }

      if (-not (Invoke-Expression $step.when)) {
        "`tBypassed because of: [$($step.when)] = $(Invoke-Expression $step.when)" | f-log-info | Out-Null
        return
      }

      $logOutputs = @()
      $global:LASTEXITCODE = 0
      "Invoke-Step:powershell: {`n$($step.powershell)}" | f-log-dbg
      if ($config.attributes.pwshake_dry_run) {
        "`tBypassed because of -DryRun: $($config.attributes.pwshake_dry_run)" | f-log-info `
       
        return
      }
      Invoke-Expression $step.powershell -ErrorAction 'Continue' *>&1 | Tee-Object -Variable logOutputs `
      | f-log-min
      if ((($LASTEXITCODE -ne 0) -or (-not $?)) -and ($step.on_error -eq 'throw')) {
        $lastErr = $logOutputs | Where-Object { $_ -is [Management.Automation.ErrorRecord] } | Select-Object -Last 1
        if (-not $lastErr) {
          $lastErr = "$($step.name) failed."
        }
        throw $lastErr
      }
    } catch {
      $_ | f-log-err
      if ($step.on_error -eq 'throw') {
        (Peek-Context).thrown = $true
        throw $_
      }
    } finally {
      ${global:pwshake-context}.hooks['invoke-step'].onExit | ForEach-Object {
        "Invoke-Step:finally:{$_}" | f-log-dbg; Invoke-Expression $_
      }
    }
  }
}
