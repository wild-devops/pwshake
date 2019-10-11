[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [hashtable]$attributes = @{
      api_token = "$env:PSGALLERY_API_TOKEN"
   }
)
$ErrorActionPreference = "Stop"

Write-Host "Publishing the PWSHAKE module`n"

if (-not $attributes['api_token']) {
  throw "`$attributes['api_token'] is empty."
}

Publish-Module -Path "$PSScriptRoot/../pwshake" -Repository PSGallery -NuGetApiKey $attributes['api_token'] -ErrorAction Stop -Force
