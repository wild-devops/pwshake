function Normalize-Step {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false)]
      [object]$item,

      [Parameter(Position = 1, Mandatory = $false)]
      [hashtable]$config = @{}
    )    
    process {
        $ErrorActionPreference = "Stop"

        if (-not $item) { return $null }

        $step = @{
            name = Coalesce $item.name, "step_$([Math]::Abs($item.GetHashCode()))";
            when = (Normalize-When $item);
            work_dir = Coalesce $item.work_dir, $item.in;
            on_error = Coalesce $item.on_error, 'throw';
            powershell = Coalesce $item.powershell, $item.pwsh;
        }

        if ($item -is [string]) {
            $step = Merge-Hashtables $step @{ name = $item; script = $item }
        } elseif ($item -is [Hashtable]) {
            $step = Merge-Hashtables $step $item
<#
            $reserved_keys = $step.Keys + $config.templates.Keys + ${pwshake-context}.templates.Keys
            if ($item.Keys.Length -eq 1) {
                $key = $item.Keys | Select-Object -First 1
                if (-not ($key -in $reserved_keys)) {
                    $step = Normalize-Step (Merge-Hashtables $step $item) $config
                }
            } else {

            }
#>
        } else {
            throw "Unknown Task item type: $($item.GetType().Name)"
        }

        foreach ($key in ${pwshake-context}.templates.Keys) {
            if ($step.Keys -contains $key) {
                $step = Merge-Hashtables ${pwshake-context}.templates[$key] $step
                $step.powershell = ${pwshake-context}.templates[$key].powershell
                #Write-Host "<<step>>:`n$(cty $step)"
                break;
            }
        }

        return $step
    }
}
