$ErrorActionPreference = "Stop"

Describe "PWSHAKE examples" {

    Get-ChildItem -Path "$PSScriptRoot/../examples" -Include *pwshake.yaml -Recurse | ForEach-Object {
        $example = $_.FullName  
        Context $example {
            { Invoke-pwshake $example -MetaData 'pwshake_verbosity=Normal'} | Should -Not -Throw
        }
    }
}
