[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [hashtable]$attributes = @{
      windows_image = "microsoft/nanoserver"
   }
)

Write-Host "Creating Windows from '$($attributes.windows_image)' image"
