function Build-Step {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [object]$step
    )
    process {
        "Build-Step:In:`$_`n$(ConvertTo-Yaml $_)" | f-log-dbg

        if ($null -eq $step) {
            return $null
        }
        else {
            $step = $step | Build-Item | Build-Template
        }
        "Build-Step:Build-Template:$(@{'$step'=$step} | ConvertTo-Yaml)" | f-log-dbg

        $step = Merge-Hashtables @{
            name       = $step.name;
            when       = Build-When $step;
            work_dir   = Coalesce $step.work_dir, $step.in;
            on_error   = Coalesce $step.on_error, 'throw';
            powershell = Coalesce $step.powershell, $step.pwsh;
        } $step

        "Build-Step:Out:$(@{'$step'=$step} | ConvertTo-Yaml)" | f-log-dbg
        return $step
    }
}
