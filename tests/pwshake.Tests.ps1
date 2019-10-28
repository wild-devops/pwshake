$ErrorActionPreference = "Stop"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12'

if (-not (Get-Module -Name Pester | Where-Object Version -eq 4.9.0)) {
    Install-Module -Name Pester -Repository PSGallery -RequiredVersion 4.9.0 -Force -SkipPublisherCheck -Scope CurrentUser
    Import-Module -Name Pester -Force -Global
}

$result = Invoke-Pester -Script $PSScriptRoot\module.Scope.ps1 -PassThru

if ($result.FailedCount) {
    throw "Tests failed."
}