function Load-Modules {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [hashtable]$config = (Peek-Config)
  )
  process {
    Get-ChildItem -Path (Split-Path $PSScriptRoot -Parent | Join-Path -ChildPath  modules/*) -Recurse -Include *.psm1 -File | ForEach-Object FullName | Sort-Object -Unique | ForEach-Object {
      Import-Module $_ -Force -DisableNameChecking -WarningAction SilentlyContinue # -Verbose
    }
    return $config
  }
}
