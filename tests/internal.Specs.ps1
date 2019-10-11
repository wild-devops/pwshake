$ErrorActionPreference = "Stop"

Describe "PWSHAKE internal functions" {

    Get-ChildItem -Path $PSScriptRoot -Filter *.Context.ps1 | ForEach-Object {
        . $_.FullName
    }
}
