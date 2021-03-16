function global:Log-Debug {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [object]$message,

      [Parameter(Position = 1, Mandatory = $false)]
      [hashtable]$config = (Coalesce (Peek-Config), @{}),

      [switch]$Force
  )
    process {
      $verbosity = [pwshake.VerbosityLevel](Coalesce $config.attributes.pwshake_verbosity, 'Default')

      $color = "$($Host.PrivateData.WarningForegroundColor)"
      if ($Force) {
        $color = 'Cyan'
      } elseif ((${global:pwshake-context}.options.debug_filter) `
          -and ($message -notmatch ${global:pwshake-context}.options.debug_filter)) {
        return
      } elseif ($verbosity -lt [pwshake.VerbosityLevel]::Debug) {
        return
      }

      "DEBUG: $message" | Log-Output -ForegroundColor $color
    }
 }
