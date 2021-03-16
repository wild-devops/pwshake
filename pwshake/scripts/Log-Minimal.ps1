function global:Log-Minimal {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [object]$message,

      [Parameter(Position = 1, Mandatory = $false)]
      [hashtable]$config = (Coalesce (Peek-Config), @{})
  )
    process {
      $verbosity = [PWSHAKE.VerbosityLevel](Coalesce $config.attributes.pwshake_verbosity, 'Default')
      if ($verbosity -lt [PWSHAKE.VerbosityLevel]::Minimal) { return }

      $message | Log-Output -Config $config
    }
 }
