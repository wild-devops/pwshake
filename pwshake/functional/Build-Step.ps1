function Build-Step {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [object]$step
    )
    process {
        ":In:" | f-log-dbg '$_'

        if ($null -eq $step) {
            return $null
        }

        $step = $step | Build-Item | ForEach-Object {
            $_, @{
                name       = $_.name
                when       = Build-When $_
                work_dir   = Coalesce $_.work_dir, $_.in
                on_error   = Coalesce $_.on_error, 'throw'
                powershell = Coalesce $_.powershell, $_.pwsh
            } | Merge-Object -Strategy Override
        }

        ":Out:" | f-log-dbg '$step'
        return $step
    }
}