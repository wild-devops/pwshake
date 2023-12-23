$ErrorActionPreference = "Stop"

Describe "PWSHAKE public functions" {

    Context "Invoke-pwshake" {
        It "Should return by Get-Command -Name Invoke-pwshake" {
            Get-Command -Name Invoke-pwshake | Should -Not -BeNullOrEmpty
        }

        It "Should return by Get-Command -Name pwshake" {
            Get-Command -Name pwshake | Should -Not -BeNullOrEmpty
        }

        It "Should not throw on ./examples/4.complex/v1.0/complex_pwshake.yaml" {
            {
                Invoke-pwshake (Join-Path $PSScriptRoot\.. -ChildPath "examples\4.complex\v1.0\complex_pwshake.yaml") `
                    @("create_linux_istance","deploy_shake") `
                    "$PWD/examples/4.complex/v1.0/metadata"
            } | Should -Not -Throw
        }

        It "Should not throw on .\examples\4.complex\v1.0\create_env_pwshake.yaml" {
            {
                Invoke-pwshake (Join-Path $PSScriptRoot\.. -ChildPath "examples\4.complex\v1.0\create_env_pwshake.yaml") `
                    @("create_environment") `
                    "$PWD/examples/4.complex/v1.0/metadata"
            } | Should -Not -Throw
            $pwshake_log = Get-Content (Join-Path $PSScriptRoot\.. -ChildPath "examples\4.complex\v1.0\create_env_pwshake.log")
            $pwshake_log | Select-String '] Here chef step\.' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Deploy role webui' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Here firewall rules for webui' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Deploy role api' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Here firewall rules for api' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Deploy role static' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Here firewall rules for static' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] $(("$PWD/examples\4.complex\v1.0\attributes_overrides\local.yaml').Replace('\','\\"))" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] 00000000-0000-0000-0000-000000000000" | Should -Not -BeNullOrEmpty
        }

        It 'Should not throw on the example invocation of nested includes' {
            {
                Invoke-pwshake ("$PWD/examples\4.complex\v1.0\module\pwshake.yaml') -Roles 'deep"
            } | Should -Not -Throw
            $pwshake_log = Get-Content ("$PWD/examples\4.complex\v1.0\module\pwshake.log")
            $pwshake_log | Select-String "] Hello from 'Deep buried role'" | Should -Not -BeNullOrEmpty
        }

        It 'Should throw on the example invocation of generated errors' {
            {
                Invoke-pwshake ("$PWD/examples\4.complex\v1.0\module\pwshake.yaml') -Roles 'errors' -Metadata @{py_arg='0"}
            } | Should -Throw 'ZeroDivisionError: division by zero'
            $pwshake_log = Get-Content ("$PWD/examples\4.complex\v1.0\module\pwshake.log")
            $pwshake_log | Select-String "] simulate error0" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] simulate error1" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] ERROR: simulate error1" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] simulate error2" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] simulate error3" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] ERROR: simulate error4" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] start0" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] noerr0" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] err0" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] ERROR: ZeroDivisionError: division by zero" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] Try call file: pwshake0" | Should -BeNullOrEmpty
        }

        It 'Should throw on the example invocation of Invoke-Command' {
            {
                Invoke-pwshake ("$PWD/examples\4.complex\v1.0\module\pwshake.yaml") `
                    -Roles 'errors' -Metadata @{pwsh_arg='42'} -Verbosity 'Minimal'
            } | Should -Throw -ExceptionType ([Management.Automation.CommandNotFoundException])
            $pwshake_log = Get-Content ("$PWD/examples\4.complex\v1.0\module\pwshake.log")
            $pwshake_log | Select-String "] simulate error0" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] simulate error1" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] ERROR: simulate error1" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] simulate error2" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] simulate error3" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] ERROR: simulate error4" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] start42" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] noerr0" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] err0" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] noerr1" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] err1" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] noerr2" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] err2" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] noerr3" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] err3" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] noerr4" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] err4" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] end" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] Try call file: dir42" | Should -Not -BeNullOrEmpty
        }

        It 'Should throw on the example invocation with logging to json and custom format' {
            {
                Invoke-pwshake ("$PWD/examples\1.hello\v1.5\my_pwshake.yaml") -MetaData @{
                    on_error='throw'
                    pwshake_json_log_format='@{msg=$_}'
                } -Verbosity 'Information'
            } | Should -Throw 'PWSHAKE is sick!'

            $pwshake_log = (Get-Content ("$PWD/examples\1.hello\v1.5\my_pwshake.log") -Raw) `
                          -replace '\[\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\]\s', ''
            (Get-Content ("$PWD/examples\1.hello\v1.5\my_pwshake.log.json") `
              | ConvertFrom-Json | ForEach-Object msg) | Should -Be $pwshake_log
        }
    }
}
