$ErrorActionPreference = "Stop"

Describe "PWSHAKE internal functions" {

    try {
        # since all internal functions need to peek some existing config and then change it
        ${global:pwshake-context}.invocations.Push(@{
                arguments = @{}
                config    = @{
                    attributes = @{
                        pwshake_verbosity = ${global:pwshake-context}.options.tests_verbosity
                        work_dir       = "$PWD"
                        pwshake_path      = "$PWD"
                        pwshake_log_path  = "TestDrive:\mock.log"
                    }
                }
            })

        Get-ChildItem -Path $PSScriptRoot -Filter "*$(${global:pwshake-context}.options.tests_context)*.Context.ps1" | ForEach-Object {
            . $_.FullName
        }
    }
    finally {
        ${global:pwshake-context}.invocations.Pop() | Out-Null
    }
}
