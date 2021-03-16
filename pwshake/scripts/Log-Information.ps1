function global:Log-Information {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [object]$message,

      [Parameter(Position = 1, Mandatory = $false)]
      [hashtable]$config = (Coalesce (Peek-Config), @{})
  )
    process {
      $verbosity = [PWSHAKE.VerbosityLevel](Coalesce $config.attributes.pwshake_verbosity, 'Default')
      if ($verbosity -lt [PWSHAKE.VerbosityLevel]::Normal) { return }

      $message | Log-Output -Config $config
    }
 }
