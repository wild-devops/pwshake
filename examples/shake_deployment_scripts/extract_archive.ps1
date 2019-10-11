[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [hashtable]$attributes = @{
      archive_path = "SHAKE.zip";
      extract_to = "C:\shake"
   }
)

Write-Host "Extracting '$($attributes.archive_path)' to '$($attributes.extract_to)'"
