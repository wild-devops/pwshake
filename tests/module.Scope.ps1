InModuleScope pwshake {
    function Get-RelativePath { param ([string]$relativePath)
        Join-Path (Split-Path $PSScriptRoot -Parent) -ChildPath $relativePath
    }

    # to speed up testing of recursions
    ${global:pwshake-context}.options.max_depth = 20

    Get-ChildItem -Path $PSScriptRoot -Filter *.Specs.ps1 | ForEach-Object {
        . $_.FullName
    }
}
