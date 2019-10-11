function Load-Config {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$YamlPath
    )
    process {

        if (-not (Test-Path $yamlPath)) {
            throw "$yamlPath does not exist."
        }

        $config = Get-Content $yamlPath -Raw | ConvertFrom-Yaml | Normalize-Config

        return $config
    }
}