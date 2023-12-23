function Build-FromYaml {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$path
    )
    process {
        $ErrorActionPreference = "Stop"

        try {
            $path = Resolve-Path $path
            return Get-Content $path -Raw | f-cfy
        }
        catch [YamlDotNet.Core.YamlException] {
            throw "File '$path' is corrupted: $($_.Exception.InnerException.ToString().Split("`n")[0])"
        }
    }
}
