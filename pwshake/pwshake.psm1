$ErrorActionPreference = "Stop"

$scripts = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'scripts/*.ps1') -Recurse -ErrorAction Stop)

foreach ($script in $scripts) {
    try {
        . $script.FullName
    }
    catch {
        throw "Unable to dot source [$($script.FullName)]"
    }
}

# Shared variables
[bool]${is-Windows} = ([System.Environment]::OSVersion.Platform -match 'Win')
[bool]${is-Linux} = (-not ${is-Windows})

New-Alias -Name pwshake -Value Invoke-pwshake -Force

Export-ModuleMember -Function Invoke-pwshake -Alias pwshake