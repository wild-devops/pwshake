function Build-Config {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [hashtable]$config = @{},

    [Parameter(Position = 1, Mandatory = $true)]
    [string]$ConfigPath,

    [Parameter(Position = 2, Mandatory = $false)]
    [object]$MetaData = $null,

    [Parameter(Mandatory = $false)]
    [string]$Verbosity = 'Normal',

    [Parameter(Mandatory = $false)]
    [bool]$DryRun = $false
  )
  Process {
    $config = Resolve-Path $ConfigPath | Build-FromYaml | Align-Config

    $config.attributes.pwshake_path = "$(Split-Path $ConfigPath -Resolve)"
    $config.attributes.pwshake_log_path = Coalesce $config.attributes.pwshake_log_path, (Join-Path -Path $config.attributes.pwshake_path -ChildPath "$((Resolve-Path $ConfigPath | Get-Item).BaseName).log").ToString()
    $config.attributes.pwshake_module_path = "$((Peek-Context).module.path)"
    $config.attributes.pwshake_version = "$((Peek-Context).module.version)"
    $config.attributes.work_dir = Coalesce $config.attributes.work_dir, "$(Get-Location)"
    $config.attributes.pwshake_verbosity = Coalesce $config.attributes.pwshake_verbosity, $Verbosity
    if ($DryRun) {
      $config.attributes.pwshake_dry_run = Coalesce $config.attributes.pwshake_dry_run, $DryRun
    }

    if (-not $config.scripts_directories.Count) {
      $config.scripts_directories = @('.')
    }
    elseif (-not $config.scripts_directories.Contains('.')) {
      $config.scripts_directories += '.'
    }

    if (Test-Path $config.attributes.pwshake_log_path) {
      Remove-Item -Path $config.attributes.pwshake_log_path -Force
    }
    if (Test-Path "$($config.attributes.pwshake_log_path).json") {
      Remove-Item -Path "$($config.attributes.pwshake_log_path).json" -Force
    }

    return $config
  }
}
