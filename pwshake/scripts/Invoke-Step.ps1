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
      "Invoke-Step:In:$(@{'$_'=$_} | ConvertTo-Yaml)" | f-dbg
      $step = $step | Build-Step
      "Invoke-Step:Build-Step:$(@{'$step'=$step} | ConvertTo-Yaml)" | f-dbg

      $caption = "Execute step: $($step.name)"

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
        Log-Debug "Invoke-Step:try:{$_}"; Invoke-Expression $_
      }

      if (-not (Invoke-Expression $step.when)) {
        Log-Information "`tBypassed because of: [$($step.when)] = $(Invoke-Expression $step.when)"
        return
      }

      $logOutputs = @()
      $global:LASTEXITCODE = 0
      Log-Debug "Invoke-Step:powershell: {`n$($step.powershell)}"
      if ($config.attributes.pwshake_dry_run) {
        "`tBypassed because of -DryRun: $($config.attributes.pwshake_dry_run)" | Log-Information 6>&1 `
        | tee-sb | Write-Host
        return
      }
      Invoke-Expression $step.powershell -ErrorAction 'Continue' *>&1 | Tee-Object -Variable logOutputs `
      | Log-Minimal 6>&1 | tee-sb | Write-Host
      if ((($LASTEXITCODE -ne 0) -or (-not $?)) -and ($step.on_error -eq 'throw')) {
        $lastErr = $logOutputs | Where-Object { $_ -is [Management.Automation.ErrorRecord] } | Select-Object -Last 1
        if (-not $lastErr) {
          $lastErr = "$($step.name) failed."
        }
        throw $lastErr
      }
    }
    catch {
      $last_error = $_
      ${global:pwshake-context}.hooks['invoke-step'].onError | ForEach-Object {
        Log-Debug "Invoke-Step:catch:{$_}"; Invoke-Expression $_
      }
    }
    finally {
      ${global:pwshake-context}.hooks['invoke-step'].onExit | ForEach-Object {
        Log-Debug "Invoke-Step:finally:{$_}"; Invoke-Expression $_
      }
    }
  }
}
