function global:Log-Verbose {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false)]
      [object]$message,

      [Parameter(Position = 1, Mandatory = $true)]
      [hashtable]$config
  )    
    process {
        $message | Log-Output -Config $config -Verbosity "Verbose"
    }
 }
