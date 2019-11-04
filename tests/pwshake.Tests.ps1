$ErrorActionPreference = "Stop"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12'

if (-not (Get-Module -Name Pester | Where-Object Version -eq 4.9.0)) {
    Install-Module -Name Pester -Repository PSGallery -RequiredVersion 4.9.0 -Force -SkipPublisherCheck -Scope CurrentUser
    Import-Module -Name Pester -Force -Global
}

$mod = (Invoke-Expression (Get-Content $PSScriptRoot\..\pwshake\pwshake.psd1 -Raw))

foreach ($dep in $mod.RequiredModules) {
  $aval = Get-Module -ListAvailable `
    | Where-Object {($_.Name -eq $dep.ModuleName) -and ($_.Version -eq $dep.RequiredVersion)}
  if (-not $aval) {
    Install-Module -Name $dep.ModuleName -Repository PSGallery -RequiredVersion $dep.RequiredVersion -Force -Scope CurrentUser
    Import-Module -Name $dep.ModuleName -Force -Global -DisableNameChecking
  }
}

#$result = Invoke-Pester -Script $PSScriptRoot/module.Scope.ps1 -PassThru
$result = Invoke-Pester -Script $PSScriptRoot/module.Scope.ps1 -PassThru -TestName "PWSHAKE examples"

if ($result.FailedCount) {
    throw "Tests failed."
}