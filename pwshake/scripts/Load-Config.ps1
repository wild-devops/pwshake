function Load-Config {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$YamlPath
    )
    process {

        return $yamlPath | Normalize-Yaml | Normalize-Config
    }
}