[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Context = '',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Error', 'Warning', 'Minimal', 'Information', 'Verbose', 'Debug', 'Normal', 'Default')]
    [string]$Verbosity = 'Error'
)

BeforeDiscovery {
    $examples = Get-ChildItem -Path "$PWD\examples" -File -Filter "*${Context}*_pwshake.yaml" -Recurse | ForEach-Object FullName | Sort-Object
}

Describe "PWSHAKE examples" -Tag 'examples' {
    Context '<_>' -ForEach $examples {
        It "Should not throw on: <_>" {
            {
                Invoke-pwshake -ConfigPath $_ -Verbosity ${global:pwshake-context}.options.tests_verbosity
            } | Should -Not -Throw
        }
    }
}
