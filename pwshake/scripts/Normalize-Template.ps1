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

        Log-Debug "Normalize-Template:`$step`n$($step | cty)" $config

        if ($depth -gt ${pwshake-context}.max_depth) {
            throw "Circular reference detected for template:`n$(ConvertTo-Yaml $item)"
        }

        Log-Debug "Normalize-Template:`$key = '$key'" $config
        $step.Remove('powershell')
        $template = Merge-Hashtables ${pwshake-context}.templates[$key] $step
        
        if ($step[$key] -is [hashtable]) {
            $template = Merge-Hashtables $template $step[$key]
            $template.Remove($key)
        } elseif (-not $step[$key]) {
            $template.Remove($key)
        }

        $yaml = $template | ConvertTo-Yaml
        foreach ($eval in (Get-Matches $yaml '\$\[\[(?<eval>.*?)\]\]' 'eval')) {
            $yaml = $yaml.Replace("`$[[$eval]]", (Invoke-Expression $eval | ConvertTo-Json -Compress -Depth 99))
        }
        $template = $yaml | ConvertFrom-Yaml

        if (-not $template.powershell) {
            $template.Remove($key)
            $key = Compare-Object (@() + $template.Keys) (@() + ${pwshake-context}.templates.Keys) -PassThru -IncludeEqual -ExcludeDifferent # intersection
            $template = Normalize-Template $template $key $config ($depth + 1)
        }

        Log-Debug "Normalize-Template:`$template`n$($template | cty)" $config
        return $template
    }
}