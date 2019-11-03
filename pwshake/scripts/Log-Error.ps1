function Log-Error {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [object]$message,

      [Parameter(Position = 1, Mandatory = $true)]
      [hashtable]$config,

      [Parameter(Position = 2, Mandatory = $false)]
      [bool]$Rethrow = $false
  )    
    process {
        $message | Log-Output -Config $config -Rethrow $Rethrow -Verbosity "Error"
    }
 }
