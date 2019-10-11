$ErrorActionPreference = "Stop"

Import-Module $PSScriptRoot\..\pwshake\pwshake.psd1 -Force -Global -DisableNameChecking

InModuleScope pwshake {
    function Get-RelativePath { param ([string]$relativePath)
        Join-Path (Split-Path $PSScriptRoot -Parent) -ChildPath $relativePath
    }
    
    Get-ChildItem -Path $PSScriptRoot -Filter *.Specs.ps1 | ForEach-Object {
        . $_.FullName
    }
}
