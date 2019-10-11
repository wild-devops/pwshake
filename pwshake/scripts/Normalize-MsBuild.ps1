function Normalize-MsBuild {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $false)]
        [object]$item,

        [Parameter(Position = 1, Mandatory = $false)]
        [hashtable]$config = @{}
        )    
    process {
        $ErrorActionPreference = "Stop"
        if (-not $item) {
            return $null
        }

        $msbuild = @{
            project = (Normalize-Path $item.project $config);
            targets = $item.targets;
            properties = $item.properties;
        }

        if ($item -is [string]) {
            $msbuild.project = (Normalize-Path $item $config)
        } elseif ($item.GetType() -ne [hashtable]) {
          throw "Unknown msbuild item type: $($item.GetType().Name)"
        }

        return $msbuild
    }
}
