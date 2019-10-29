# Bootstrapper script for those who wants to run pwshake without prior importing the module.
# Example run from PowerShell:
# PS>./pwshake.ps1 ./examples/pwshake_config.yaml @("create_linux_istance","deploy_shake") @{override_to="local";artifact_id="42"}

# Must match parameter definitions for pwshake.psm1/Invoke-pwshake function
# otherwise named parameter binding fails
[CmdletBinding()]
param(
  [Alias("Path")]
  [Parameter(Position = 0, Mandatory = $false)]
  [string]$ConfigPath = "$PSScriptRoot/pwshake.yaml",

  [Alias("RunLists", "Roles")]
  [Parameter(Position = 1, Mandatory = $false)]
  [object[]]$Tasks = @(),

  [Parameter(Position = 2, Mandatory = $false)]
  [object]$MetaData = $null,

  [Alias("WhatIf", "Noop")]
  [Parameter(Mandatory = $false)]
  [switch]$DryRun,

  [Parameter(Mandatory = $false)]
  [string]$Version = "1.2.0"
)

$ErrorActionPreference = "Stop"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12'

if ([System.Environment]::OSVersion.Platform -match 'Win') {
  Import-Module -Name PackageManagement -Force -Global -DisableNameChecking
  if (-not (Get-PackageProvider -ListAvailable | Where-Object Name -eq NuGet)) {
    Set-PackageSource -Name PSGallery -Trusted -Force | Out-Null
    Install-PackageProvider NuGet -Force | Out-Null
    Import-PackageProvider NuGet -Force | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted | Out-Null
  }
}

if (Test-Path $PSScriptRoot\pwshake\pwshake.psd1) {
  $mod = (Invoke-Expression (Get-Content $PSScriptRoot\pwshake\pwshake.psd1 -Raw))

  foreach ($dep in $mod.RequiredModules) {
    $aval = Get-Module -ListAvailable `
      | Where-Object {($_.Name -eq $dep.ModuleName) -and ($_.Version -eq $dep.RequiredVersion)}
    if (-not $aval) {
      Install-Module -Name $dep.ModuleName -Repository PSGallery -RequiredVersion $dep.RequiredVersion -Force -Scope CurrentUser
      Import-Module -Name $dep.ModuleName -Force -Global -DisableNameChecking
    }
  }
  
  Import-Module $PSScriptRoot\pwshake\pwshake.psd1 -Force -Global -DisableNameChecking
} else {
  Get-Module -ListAvailable | Where-Object {($_.Name -eq 'pwshake') -and ($_.Version -lt $version)} | Remove-Module -Force

  if (-not (Get-Module -ListAvailable | Where-Object {($_.Name -eq 'pwshake') -and ($_.Version -eq $version)})) {
    Install-Module -Name pwshake -Repository PSGallery -RequiredVersion $version -Force -Scope CurrentUser
  }
  Import-Module -Name pwshake -RequiredVersion $version -Force -Global -DisableNameChecking
}

Invoke-pwshake -ConfigPath $configPath -Tasks $Tasks -MetaData $MetaData -DryRun:$DryRun
