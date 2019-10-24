function Execute-Step {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $true)]
      [hashtable]$config,
  
      [Parameter(Position = 1, Mandatory = $true)]
      [hashtable]$step
    )    
    process {
        $ErrorActionPreference = "Continue"

        if (-not (Invoke-Expression $step.when)) {
            Write-Host "`t`tBypassed because of when: [$($step.when)] = $(Invoke-Expression $step.when)"
            return;
        }

        if ($step.template) {
            Execute-Step $config (Normalize-Template $step $config)
        } elseif ($step.script) {
            $paths = $config.scripts_directories | ForEach-Object { Join-Path $config.attributes.pwshake_path -ChildPath $_ }
            $script_path = Get-ChildItem $paths -File `
                | Where-Object BaseName -eq $step.script `
                | Select-Object -ExpandProperty FullName
            Write-Host "Script file: $script_path"
            if (-not $script_path) { throw "Script file: $($step.script).ps1 not found." }
            & $script_path -attributes $config.attributes
        } elseif ($step.powershell) {
            Write-Host "powershell: $($step.powershell)"
            Invoke-Expression $step.powershell
        } elseif ($step.cmd) {
            $cmd = ""
            foreach ($item in ($step['cmd'] -split '\^\s*\n')) {
                $cmd += $item
            }
            Cmd-Shell $cmd -errorMessage "$($step.name) failed."
        } elseif ($step.invoke_tasks) {
            $tasks = Arrange-Tasks $config $step.invoke_tasks
            foreach ($task in $tasks) {
                Invoke-Task $task $config
            }
        }

        if (-not $?) { throw "$($step.name) failed." }
    }
}
