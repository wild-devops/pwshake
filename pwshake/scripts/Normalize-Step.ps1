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
        
        if ($depth -gt ${pwshake-context}.max_depth) {
            throw "Circular reference detected for step:`n$(ConvertTo-Yaml $item)"
        }

        Log-Debug "Normalize-Step:`$item`n$(ConvertTo-Yaml $item)" $config

        if (-not $item) {
            return $null
        } elseif ($item -is [string]) {
            $item = @{name="$item";script="$item"}
        } elseif ($item -is [hashtable]) {
            if ($item.Keys.Count -eq 1) {
                $key = "$($item.Keys)"
                if ($item.$($key) -is [hashtable]) {
                    $item = $item.$($key)
                    if (${pwshake-context}.templates.Keys -contains $key) {
                        $item.Add($key, $null)
                        if (-not ($item.Keys -contains 'name')) {
                            $item.Add('name', "${key}_$([Math]::Abs($item.GetHashCode()))")
                        }
                    } elseif (-not ($item.Keys -contains 'name')) {
                        $item.Add('name', $key)
                    }
                }
             }
        } else {
            throw "Unknown step type: $($item.GetType().Name)"
        }

        $step = Merge-Hashtables @{
            name = Coalesce $item.name, "step_$([Math]::Abs($item.GetHashCode()))";
            when = (Normalize-When $item);
            work_dir = Coalesce $item.work_dir, $item.in;
            on_error = Coalesce $item.on_error, 'throw';
            powershell = Coalesce $item.powershell, $item.pwsh;
        } $item

        if ($item -is [Hashtable]) {
            if ($item.Keys.Count -eq 1) {
                $key = $item.Keys[0]
                $content = $item[$key][0]
                Log-Debug "Normalize-Step:`$content`n$(ConvertTo-Yaml $content)" $config
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

        Log-Debug "Normalize-Step:`$step`n$(ConvertTo-Yaml $step)" $config

        return $step
    }
}
