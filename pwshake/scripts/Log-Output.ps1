function global:Log-Output {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [object]$message,

      [Parameter(Position = 1, Mandatory = $false)]
      [hashtable]$config = (Coalesce (Peek-Config), @{}),

      [Parameter(Position = 2, Mandatory = $false)]
      [bool]$Rethrow = $false,

      [Parameter(Mandatory = $false)]
      [string]$ForegroundColor = $null
  )
    process {
        if ($message -is [Management.Automation.ErrorRecord]) {
            if ($Rethrow) {
                throw $message
            } else {
                $message = "$message" | f-mask-secured
                "ERROR: ${message}" | f-tmstmp | Add-Content -Path $config.attributes.pwshake_log_path
                Write-Host $message -ForegroundColor 'Red'
            }
        } else {
            $message = "$message" | f-mask-secured
            $message | f-tmstmp | Add-Content -Path $config.attributes.pwshake_log_path
            if ($ForegroundColor) {
                Write-Host $message -ForegroundColor $ForegroundColor
            } else {
                Write-Host $message
            }
        }
    }
}
