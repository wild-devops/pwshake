function global:Log-Warning {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [object]$message,

      [Parameter(Position = 1, Mandatory = $false)]
      [hashtable]$config = (Coalesce (Peek-Config), @{})
  )
    process {
      $verbosity = [pwshake.VerbosityLevel](Coalesce $config.attributes.pwshake_verbosity, 'Default')
      if ($verbosity -lt [pwshake.VerbosityLevel]::Warning) { return }

      $message | Log-Output -Config $config
    }
 }
