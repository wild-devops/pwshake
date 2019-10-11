[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [hashtable]$attributes = @{
      real_path = "C:\shake\4.2";
      links_to = "M:\shake\current"
   }
)

Write-Host "Creating symlinks from '$($attributes.real_path)' to '$($attributes.links_to)'"
