function global:Log-Error {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Management.Automation.ErrorRecord]$error,

      [Parameter(Position = 1, Mandatory = $false)]
      [hashtable]$config = (Coalesce (Peek-Config), @{}),

      [Parameter(Position = 2, Mandatory = $false)]
      [bool]$Rethrow = $false
  )
    process {
      $verbosity = [pwshake.VerbosityLevel](Coalesce $config.attributes.pwshake_verbosity, 'Default')
      if ($verbosity -lt [pwshake.VerbosityLevel]::Error) { return }

      $error | f-error | f-tmstmp | Add-Content -Path $config.attributes.pwshake_log_path -Encoding UTF8
      $error | f-error | Write-Host -ForegroundColor Red

      if ($Rethrow) {
        throw $error
      }
    }
 }
