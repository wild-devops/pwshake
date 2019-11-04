function Normalize-Template {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false)]
      [hashtable]$step = @{},

      [Parameter(Position = 1, Mandatory = $false)]
      [string]$key,

      [Parameter(Position = 2, Mandatory = $false)]
      [hashtable]$config = @{},

      [Parameter(Position = 3, Mandatory = $false)]
      [int]$depth = 0
    )    
    process {
        $ErrorActionPreference = "Stop"

        Log-Debug "== Normalize-Template:`$step ==`n$($step | cty)" $config
Write-Host "== Normalize-Template:`$step ==`n$($step | cty)"

        if ($depth -gt ${pwshake-context}.max_depth) {
            throw "Circular reference detected for template:`n$(ConvertTo-Yaml $item)"
        }

        Log-Debug "== Normalize-Template:`$key = '$key' ==" $config
        $template = Merge-Hashtables $step ${pwshake-context}.templates[$key]
        
        if ($step[$key] -is [hashtable]) {
            $template = Merge-Hashtables $template $step[$key]
            $template.Remove($key)
        }

        $yaml = $template | ConvertTo-Yaml
        foreach ($subst in (Get-Matches $yaml '\$\[\[(?<eval>.*?)\]\]' 'eval')) {
            $yaml = $yaml.Replace("`$[[$subst]]", (Invoke-Expression "$($subst) | ConvertTo-Json"))
        }
        $template = $yaml | ConvertFrom-Yaml
        Log-Debug "== Normalize-Template:`$template ==`n$($template | cty)" $config
Write-Host "== Normalize-Template:`$template ==`n$($template | cty)"

        if (-not $template.powershell) {
            $key = Compare-Object (@() + $template.Keys) (@() + ${pwshake-context}.templates.Keys) -PassThru -IncludeEqual -ExcludeDifferent # intersection
            $template = Normalize-Template $template $key $config ($depth + 1)
        }

        return $template
    }
}