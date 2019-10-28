function Invoke-Step {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true)]
    [hashtable]$config,

    [Parameter(Position = 1, Mandatory = $true)]
    [object]$step,

    [Parameter(Position = 2, Mandatory = $false)]
    [string]$work_dir = ''
  )    
  process {
    $ErrorActionPreference = "Continue"

    $step = Normalize-Step $step $config
    $throwOn = ($step.on_error -eq 'throw')

    if (-not (Invoke-Expression $step.when)) {
      Log-Output "`t`tBypassed because of: [$($step.when)] = $(Invoke-Expression $step.when)" $config
      continue;
    }

    try {
      if ($work_dir) {
        # Since actual execution is performed in the $step that can contain it's own .work_dir property
        # overrride it only if the $step.work_dir is empty
        if (-not $step.work_dir) { 
          $step.work_dir = $work_dir
        } 
      }
      Push-Location (Normalize-Path "$($step.work_dir)" $config)

      Log-Output "Execute step: $($step.name)" $config
      $logOut = @()
      $global:LASTEXITCODE = 0
      Invoke-Expression $step.powershell *>&1 | Tee-Object -Variable logOut | Log-Output -config $config
      if ((($LASTEXITCODE -ne 0) -or (-not $?)) -and ($throwOn)) { 
        $lastErr = $logOut | Where-Object {$_ -is [Management.Automation.ErrorRecord]} | Select-Object -Last 1
        if (-not $lastErr) {
            $lastErr = "$($step.name) failed."
        }
        throw "$lastErr"
      }
    } catch {
      Log-Output $_ $config -Rethrow $throwOn
    } finally {
        Pop-Location
    }
  }
}