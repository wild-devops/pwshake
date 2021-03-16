function Get-TeamCityProperty {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$propName,

        [Parameter(Position = 1, Mandatory = $false)]
        [string]$propFile = $env:TEAMCITY_BUILD_PROPERTIES_FILE
    )
    process {
        if (-not ${teamcity-build-properties}.Keys.Count) {
            if (-not $propFile) {
                throw "`$env:TEAMCITY_BUILD_PROPERTIES_FILE is empty."
            }

            if (-not (Test-Path $propFile)) {
                throw "$propFile does not exist."
            }

            $params = Get-Content $propFile -Raw | ConvertFrom-StringData

            if ($params['teamcity.configuration.properties.file']) {
                ${teamcity-build-properties} = Get-Content $params['teamcity.configuration.properties.file'] -Raw | ConvertFrom-StringData
            } else {
                ${teamcity-build-properties} = $params
            }
        }

        if (-not ${teamcity-build-properties}[$propName]) {
            throw "Key '$propName' does not exist."
        }

        return ${teamcity-build-properties}[$propName]
    }
}
