$ErrorActionPreference = "Stop"

$scripts = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'scripts/*.ps1') -Recurse -ErrorAction Stop)

foreach ($script in $scripts) {
  try {
    . $script.FullName
  }
  catch {
    throw "Unable to dot source [$($script.FullName)]`n$($_.Exception)"
  }
}

# Shared variables
[bool]${is-Windows} = ([System.Environment]::OSVersion.Platform -match 'Win')
[bool]${is-Linux} = (-not ${is-Windows})

$_PSScriptRoot_ = $PSScriptRoot # to use inside Build-Context
[hashtable]${global:pwshake-context} = Build-Context

New-Alias -Name pwshake -Value Invoke-pwshake -Force
New-Alias -Name ctj -Value ConvertTo-Json -Force
New-Alias -Name cfj -Value ConvertFrom-Json -Force
New-Alias -Name cty -Value ConvertTo-Yaml -Force
New-Alias -Name cfy -Value ConvertFrom-Yaml -Force
if (${is-Windows}) {
  New-Alias -Name python3 -Value python.exe -Force
}
Export-ModuleMember -Function Invoke-pwshake -Alias pwshake
Export-ModuleMember -Variable 'pwshake-context'
