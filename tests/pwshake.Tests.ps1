$ErrorActionPreference = "Stop"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12'

if (-not (Get-Module -Name Pester | Where-Object Version -eq 4.6.0)) {
    Install-Module -Name Pester -Repository PSGallery -Force -SkipPublisherCheck
    Import-Module -Name Pester -Force
}

$result = Invoke-Pester -Script $PSScriptRoot\module.Scope.ps1 -PassThru

if ($result.FailedCount) {
    throw "Tests failed."
}