[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$Group = '', # examples

    [Parameter(Mandatory = $false)]
    [string]$Context = '', # resources

    [Parameter(Mandatory = $false)]
    [Alias("LogLevel")]
    [ValidateSet('Error', 'Warning', 'Minimal', 'Information', 'Verbose', 'Debug', 'Normal', 'Default')]
    [string]$Verbosity = 'Error',

    [Parameter(Mandatory = $false)]
    [hashtable]$attributes = @{} # required to run from PWSHAKE with scripts conventions
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12


if (-not (Get-Module -Name Pester | Where-Object Version -eq 4.9.0)) {
    Install-Module -Name Pester -Repository PSGallery -RequiredVersion 4.9.0 -Force -SkipPublisherCheck -Scope CurrentUser
    Import-Module -Name Pester -RequiredVersion 4.9.0  -Force -Global -DisableNameChecking -WarningAction SilentlyContinue
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

$params = @{
    Script   = "$PSScriptRoot\module.Scope.ps1"
    TestName = "PWSHAKE ${Group}*"
}
# Add coverage report on CI build
if (!!"$env:CI_PIPELINE_IID") {
    $params.CodeCoverage = "$PSScriptRoot\..\pwshake\scripts\*.ps1"
}

${global:pwshake-context}.options.tests_context = $Context
${global:pwshake-context}.options.tests_verbosity = $Verbosity

$result = Invoke-Pester -PassThru @params

if ($result.FailedCount) {
    throw "$($result.FailedCount) tests failed."
}
