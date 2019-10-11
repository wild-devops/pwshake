[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [hashtable]$attributes = @{
      linux_image = "centos:7"
   }
)

Write-Host "Creating Linux from '$($attributes.linux_image)' image"
