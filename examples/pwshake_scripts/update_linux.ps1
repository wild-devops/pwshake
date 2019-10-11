[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [hashtable]$attributes = @{
      linux_version = "7.45.6382"
   }
)

Write-Host "Updating Linux to '$($attributes.linux_version)' version"
