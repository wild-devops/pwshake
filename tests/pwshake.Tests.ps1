[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [ValidateSet('internal', 'examples', 'public', 'asserts', 'publish')]
    [string]$Group = '',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Arrange-Tasks', 'Build-Config', 'Build-Item', 'Build-MsBuild', 'Build-Path', 'Build-Pipeline', 'Build-Step', 'Build-Task', 'Build-Template', 'Interpolate-Attributes', 'Interpolate-Evals', 'Interpolate-Item', 'Load-Config', 'Log-Output', 'Merge-Arguments', 'Merge-Includes', 'Merge-MetaData', 'Override-Attributes', 'Process-Output', 'Process-Pipeline', 'Process-Step', 'Process-Task', 'Validate-ScriptBlock')]
    [string]$Context = '',

    [Parameter(Mandatory = $false)]
    [Alias("LogLevel")]
    [ValidateSet('Error', 'Warning', 'Minimal', 'Information', 'Verbose', 'Debug', 'Normal', 'Default')]
    [string]$Verbosity = 'Error',

    [Parameter(Mandatory = $false)]
    [hashtable]$attributes = @{} # required to run from PWSHAKE with scripts conventions
)

$mod = (Invoke-Expression (Get-Content $PSScriptRoot\..\pwshake\pwshake.psd1 -Raw))
foreach ($dep in $mod.RequiredModules) {
  $aval = Get-Module -Name  $dep.ModuleName -ListAvailable | ? Version -eq $dep.RequiredVersion
  if (-not $aval) {
    $options = @{
      Name            = $dep.ModuleName
      Repository      = 'PsGallery'
      RequiredVersion = $dep.RequiredVersion
      Scope           = 'CurrentUser'
      Force           = $true
      AllowClobber    = $true
      WarningAction   = 'SilentlyContinue'
    }
    Install-Module @options | Out-Null
    Import-Module -Name $dep.ModuleName -Force -Global -RequiredVersion $dep.RequiredVersion -DisableNameChecking -WarningAction SilentlyContinue
  }
}

$version = Find-Module -Name Pester -Repository PSGallery | ForEach-Object Version
if (-not (Get-Module -Name Pester | Where-Object Version -eq $version)) {
    Install-Module -Name Pester -Repository PSGallery -RequiredVersion $version -Force -SkipPublisherCheck -Scope CurrentUser -WarningAction SilentlyContinue
    Import-Module -Name Pester -RequiredVersion $version -Force -Global -DisableNameChecking -WarningAction SilentlyContinue
}

$config = [PesterConfiguration]@{
    Run = @{
    Container    = [Pester.ContainerInfo]@{
    Type         = 'File'
    Item         = (Get-Item "$PSScriptRoot\0.module.Scope.ps1")
    Data         = @{ # here the parameters for above script
        Group        = $Group
        Context      = $Context
        Verbosity    = $Verbosity}}
    PassThru     = $true}
    Output       = @{
    Verbosity    = 'Detailed'}
}
# Add coverage report on CI build
if (!!"$env:CI_PIPELINE_IID") {
    $config.CodeCoverage = @{
        Enabled = $true
        Path    = "$PSScriptRoot\..\pwshake\scripts\*.ps1"
    }
}

$result = Invoke-Pester -Configuration $config

filter f-log-err {
  param($color='Red')
  $Host.UI.WriteLine([ConsoleColor]$color,[Console]::BackgroundColor,$_)
}

if ($result.FailedCount) {
    $result.Failed | ConvertTo-Json -Depth 3 | Set-Content $PSScriptRoot/../tools/pester-result.log.json -Force
    $result.Failed | ForEach-Object {
      "Describing $($_.Block.Parent.Root.Blocks[0].ExpandedPath)" | f-log-err -c 'DarkGreen'
      "  Context $($_.Block.ExpandedName)" | f-log-err -c 'DarkCyan'
      "    [-] $($_.ExpandedName)" | f-log-err
      $_.ErrorRecord | ForEach-Object {
        if ($_.TargetObject.Message) {
          "    $($_.CategoryInfo.Reason): $($_.TargetObject.Message)" | f-log-err
        } else {
          "    $($_.CategoryInfo.Reason): $($_.Exception.ErrorRecord)" | f-log-err
        }
        if ($_.InvocationInfo) {
          "    $($_.InvocationInfo.PositionMessage)" | f-log-err
        }
        $_.ScriptStackTrace -split "`n" | Where-Object {
          ($_ -notmatch 'Pester.psm?1') -and ($_ -notmatch '\<No file\>')
        } | ForEach-Object {
          "    $_" | f-log-err
        }
      }
    }
    throw "$($result.FailedCount) tests failed."
}

# Show coverage results on CI build
if (!!"$env:CI_PIPELINE_IID") {
    $coverage = ([xml](Get-Content "$PWD/coverage.xml")).report
    $lines = $coverage.counter | Where-Object type -eq 'line'
    $total = [int]$lines.missed + [int]$lines.covered
    Write-Host "Covered $('{0:00.00}' -f (100*([int]$lines.covered/$total))) % of $total analyzed Lines in $($coverage.package.sourceFile.Count) Files."
}
