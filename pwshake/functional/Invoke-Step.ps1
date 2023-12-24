function Invoke-Step {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [object]$step,

        [Parameter(Position = 1, Mandatory = $false)]
        [hashtable]$config = (Peek-Config),

        [Parameter(Position = 2, Mandatory = $false)]
        [string]$work_dir = ''
    )
    process {
        $ErrorActionPreference = "Continue" # to collect all ErrorMessage-s from stderr (2>&1)
        try {
            "Invoke-Step:In:`n$(@{'$_'=$_} | ConvertTo-Yaml)" | f-log-dbg
            $step = $_ = $_ | Build-Step
            "Invoke-Step:Build-Step:`n$(@{'$step'=$step} | ConvertTo-Yaml)" | f-log-dbg

            $caption = "Execute step: $($step.name)"
            $caption | f-teamcity-o | f-log-info

            # skip step early
            if (-not (Invoke-Expression $step.when)) {
                "`tBypassed because of: [$($step.when)] = $(Invoke-Expression $step.when)" | f-log-info
                return;
            }

            # separate Build-Template since it might have throws on params validation
            $step, $template_key = $step | Build-Template
            $_ = $step
            if ($template_key) {
              New-Variable -Name $template_key -Value $step -Force
            }

            if ($work_dir) {
                # Since actual execution is performed in the $step that can contain it's own .work_dir property
                # override it only if the $step.work_dir is empty
                if (-not $step.work_dir) {
                    $step.work_dir = $work_dir
                }
            }
            Push-Location (Build-Path $step.work_dir)

            ${log-Err} = @();${log-Out} = @();
            $global:LASTEXITCODE = 0
            if ($config.attributes.pwshake_dry_run) {
                "`tBypassed because of -DryRun: $($config.attributes.pwshake_dry_run)" | f-log-info
                return;
            }
            "Invoke-Step:powershell: {`n$($step.powershell)}" | f-log-dbg
            &([scriptblock]::Create($step.powershell)) *>&1 -ErrorVariable log-Err | Tee-Object -Variable log-Out | f-log-min
            if (((-not $?) -or ($LASTEXITCODE -ne 0)) -and ($step.on_error -eq 'throw')) {
                $lastErr = (${log-Err} + ${log-Out}) | Where-Object { $_ -is [Management.Automation.ErrorRecord] } | Select-Object -Last 1
                if (-not $lastErr) {
                    $lastErr = ${log-Out} | Where-Object { $_ -match 'error' } | Select-Object -Last 1
                    if (-not $lastErr) {
                        $lastErr = "$($step.name) failed."
                    }
                }
                throw $lastErr
            }
        }
        catch {
            if (-not (Peek-Data).caught) {
                # if it was not caught in execution context, it should be logged
                $_ | f-log-err
            }
            if ((Coalesce $step.on_error, 'throw') -eq 'throw') { # it might be errors on early Build-Step
                (Peek-Data).caught = $true
                throw $_
            }
        }
        finally {
            Pop-Location
            $caption | f-teamcity-c | f-log-info
        }
    }
}
