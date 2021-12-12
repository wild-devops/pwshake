function Cmd-Shell {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        [string]$cmd = "echo do_nothing",

        [Parameter(Position=1, Mandatory=$false)]
        [int]$retries = 1,
        
        [Parameter(Position=2, Mandatory=$false)]
        [string]$errorMessage = $null,

        [Parameter(Position=3, Mandatory=$false)]
        [bool]$throwOnError = $true
    )
    process {
        $ErrorActionPreference = "Continue"

        if (-not $errorMessage) {
            $errorMessage = "cmd-shell: '$cmd' failed."
        }

        $lastErr = $null; ${log-Err} = @(); ${log-Out} = @()
        if (${is-Windows}) {
            Write-Host "cmd: $cmd"
            & cmd /c $cmd *>&1 -ErrorVariable log-Err | Tee-Object -Variable log-Out
        } else {
            Write-Host "bash: $cmd"
            & bash -c $cmd *>&1 -ErrorVariable log-Err | Tee-Object -Variable log-Out
        }

        if ($LASTEXITCODE -ne 0) {
            if ($retries -gt 1) {
                $cmd | Cmd-Shell -errorMessage $errorMessage -retries ($retries - 1) -throwOnError $throwOnError
            } elseif ($throwOnError) {
                $lastErr = (${log-Err} + ${log-Out}) | Where-Object {$_ -is [System.Management.Automation.ErrorRecord]} | Select-Object -Last 1
                if ($lastErr) {
                    $errorMessage = $lastErr.Exception.Message
                }
                throw $errorMessage
            }
        }
    }
}
