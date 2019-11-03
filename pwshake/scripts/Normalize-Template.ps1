function Normalize-Template {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false)]
      [hashtable]$item,

      [Parameter(Position = 1, Mandatory = $false)]
      [hashtable]$config = @{},

      [Parameter(Position = 2, Mandatory = $false)]
      [int]$depth = 0
    )    
    process {
        $ErrorActionPreference = "Stop"

        if ($depth -gt ${pwshake-context}.max_depth) {
            throw "Circular reference detected for templates in:`n$(ConvertFrom-Yaml $item)"
        }

        if (-not $item) { return $null }

        $step = Normalize-Step $config.templates[$item.template] $config
        $step.parameters = Merge-Hashtables $step.parameters $item.parameters
        $parameters = $step.parameters.Clone()
        foreach ($param in $parameters.Keys) {
            $step = ($step | ConvertTo-Yaml).Replace("[[$param]]", $parameters[$param]) | ConvertFrom-Yaml
        }

        if ($step.template) {
            $step = Normalize-Template $step $config ($depth + 1)
        }

        return $step
    }
}
