[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [hashtable]$attributes = @{
      s3_path = "s3://shake-storage/artifacts/4.2/SHAKE.zip";
      download_to = "C:\provision\"
   }
)

Write-Host "Downloading from '$($attributes.s3_path)' to '$($attributes.download_to)'"
