function Load-Module {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [string]$path
  )
  process {
    @(Get-ChildItem -Path (Join-Path -Path $path -ChildPath scripts/*.ps1)) | ForEach-Object {
      try {
        . $_.FullName
      }
      catch {
        "$($_.Exception)" | f-log-dbg-f
        throw "Unable to dot source [$($_.FullName)]."
      }
    }
  }
}
