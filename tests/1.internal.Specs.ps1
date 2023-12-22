[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Context = '',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Error', 'Warning', 'Minimal', 'Information', 'Verbose', 'Debug', 'Normal', 'Default')]
    [string]$Verbosity = 'Error'
)

BeforeDiscovery {
    $tests = Get-ChildItem -Path $PSScriptRoot -Filter *$Context*.Context.ps1 -Recurse | ForEach-Object FullName | Sort-Object
}

Describe "<_>" -Tag 'internal' -ForEach $tests {
    . $_
}
