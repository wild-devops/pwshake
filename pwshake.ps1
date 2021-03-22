# Bootstrapper script for those who wants to run pwshake without prior importing the module.
# Example run from PowerShell:
# PS>./pwshake.ps1 ./examples/4.complex/v1.0/complex_pwshake.yaml @("create_linux_istance","deploy_shake") @{override_to="local";artifact_id="42"}

# Must match parameter definitions for pwshake.psm1/Invoke-pwshake function
# otherwise named parameter binding fails
[CmdletBinding()]
param(
  [Alias("Path","File","ConfigFile")]
  [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
  [string]$ConfigPath = "$PSScriptRoot/pwshake.yaml",

  [Alias("RunLists", "Roles")]
  [Parameter(Position = 1, Mandatory = $false)]
  [object[]]$Tasks = @(),

  [Alias("Attributes")]
  [Parameter(Position = 2, Mandatory = $false)]
  [object]$MetaData = $null,

  [Alias("LogLevel")]
  [ValidateSet('Error', 'Warning', 'Minimal', 'Information', 'Verbose', 'Debug', 'Normal', 'Default', 'Silent', 'Quiet')]
  [Parameter(Mandatory = $false)]
  [string]$Verbosity = 'Default',

  [Alias("WhatIf", "Noop")]
  [Parameter(Mandatory = $false)]
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

if ([System.Environment]::OSVersion.Platform -match 'Win') {
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
      Install-Module -Name $dep.ModuleName -Repository PSGallery -RequiredVersion $dep.RequiredVersion -Force -Scope CurrentUser | Out-Null
      Import-Module -Name $dep.ModuleName -Force -Global -DisableNameChecking
    }
  }
  
  Import-Module $PSScriptRoot\pwshake\pwshake.psm1 -Force -Global -DisableNameChecking
} else {
  $version = Find-Module -Name pwshake -Repository PSGallery | ForEach-Object Version
  Get-Module -Name pwshake -ListAvailable | Where-Object Version -lt $version | ForEach-Object {
    Uninstall-Module $_ -Force | Out-Null; Remove-Module $_ -Force | Out-Null
  }

  if (-not (Get-Module -Name pwshake -ListAvailable | Where-Object Version -eq $version)) {
    Install-Module -Name pwshake -Repository PSGallery -RequiredVersion $version -Force -Scope CurrentUser | Out-Null
  }
  Import-Module -Name pwshake -RequiredVersion $version -Force -Global -DisableNameChecking
}

$params = @{
  ConfigPath    = $ConfigPath
  Tasks         = $Tasks
  MetaData      = $MetaData
  Verbosity     = $Verbosity
  DryRun        = [bool]$DryRun
}

Invoke-pwshake @params
