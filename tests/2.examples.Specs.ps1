$ErrorActionPreference = "Stop"

Describe "PWSHAKE examples" {

    Get-ChildItem -Path "$PSScriptRoot/../examples" -Filter "*$(${global:pwshake-context}.options.tests_context)*_pwshake.yaml" -Recurse | ForEach-Object {
        $example = $_.FullName
        Context $example {
            It "Should not throw on: $example" {
                { Invoke-pwshake -ConfigPath $example -Verbosity 'Minimal' } | Should -Not -Throw
            }
        }
    }
}
