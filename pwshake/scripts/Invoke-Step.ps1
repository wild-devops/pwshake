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

    try {
      $step = Normalize-Step $step $config

      if ($work_dir) {
        # Since actual execution is performed in the $step that can contain it's own .work_dir property
        # override it only if the $step.work_dir is empty
        if (-not $step.work_dir) { 
          $step.work_dir = $work_dir
        } 
      }
      try {
        Push-Location (Normalize-Path "$($step.work_dir)" $config)

        Log-Verbose "Execute step: $($step.name)" $config
  
        if (-not (Invoke-Expression $step.when)) {
          Log-Verbose "`t`tBypassed because of: [$($step.when)] = $(Invoke-Expression $step.when)" $config
          return
        }
    
        $logOut = @()
        $global:LASTEXITCODE = 0
        Log-Debug "powershell: {$($step.powershell)}" $config
        Invoke-Expression $step.powershell *>&1 | Tee-Object -Variable logOut | Log-Normal -Config $config
        if ((($LASTEXITCODE -ne 0) -or (-not $?)) -and ($step.on_error -eq 'throw')) { 
          $lastErr = $logOut | Where-Object {$_ -is [Management.Automation.ErrorRecord]} | Select-Object -Last 1
          if (-not $lastErr) {
              $lastErr = "$($step.name) failed."
          }
          throw "$lastErr"
        }
      } finally {
        Pop-Location
      }
    } catch {
      Log-Debug "Invoke-Step: `$step`n$($step | ConvertTo-Yaml)" $config
      Log-Error $_ $config -Rethrow ((Coalesce $step.on_error, 'throw') -eq 'throw')
    }
  }
}