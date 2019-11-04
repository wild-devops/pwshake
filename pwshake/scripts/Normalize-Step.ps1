function Normalize-Step {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false)]
      [object]$item,

      [Parameter(Position = 1, Mandatory = $false)]
      [hashtable]$config = @{},

      [Parameter(Position = 2, Mandatory = $false)]
      [int]$depth = 0
    )    
    process {
        $ErrorActionPreference = "Stop"
        
        Log-Debug "Normalize-Step:`$item:`n$(ConvertTo-Yaml $item)" $config

        if ($depth -gt ${pwshake-context}.max_depth) {
            throw "Circular reference detected for step:`n$(ConvertTo-Yaml $item)"
        }

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
            if ($item.Keys.Count -eq 1) {
                $key = $item.Keys[0]
                $content = $item[$key][0]
                $reserved_keys = $step.Keys + ${pwshake-context}.templates.Keys
                if (-not ($reserved_keys -contains $key)) {
                    $step.name = $key
                }
                if ($content -is [string]) {
                    $step = Merge-Hashtables $step @{ $($key) = $content }
                } elseif ($content -is [Hashtable]) {
                    $step = Merge-Hashtables $step $content
                    $step.$($key) = $null
                } elseif (-not ($content)) {
                    $step.$($key) = $null
                } else {
                    $step.$($key) = $content
                }
            } else {
                $step = Merge-Hashtables $step $item
            }
        } else {
            throw "Unknown Task item type: $($item.GetType().Name)"
        }

        foreach ($key in ${pwshake-context}.templates.Keys) {
            if ($step.Keys -contains $key) {
                $step = Normalize-Template $step $key $config ($depth + 1)
                break;
            }
        }

        Log-Debug "Normalize-Step:`$step:`n$(ConvertTo-Yaml $step)" $config

        return $step
    }
}
