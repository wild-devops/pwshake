function global:Log-Debug {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [object]$message,

      [Parameter(Position = 1, Mandatory = $true)]
      [hashtable]$config
  )    
    process {
        "DEBUG: >>>$message<<<" | Log-Output -Config $config -Verbosity "Debug"
    }
 }
