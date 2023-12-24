function Build-FromYaml {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$path
    )
    process {
        $ErrorActionPreference = "Stop"
        try {
            $path = Resolve-Path $path
            return Get-Content $path -Raw | psyml\ConvertFrom-Yaml -AsHashtable
        }
        catch [YamlDotNet.Core.YamlException] {
            throw "File '$path' is corrupted: $($_.Exception.InnerException.ToString().Split("`n")[0])"
        }
    }
}
