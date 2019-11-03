$ErrorActionPreference = "Stop"

Describe "PWSHAKE public functions" {

    Context "Invoke-pwshake" {
        It "Should return by Get-Command -Name Invoke-pwshake" {
            Get-Command -Name Invoke-pwshake | Should -Not -BeNullOrEmpty
        }

        It "Should return by Get-Command -Name pwshake" {
            Get-Command -Name pwshake | Should -Not -BeNullOrEmpty
        }

        It "Should not throw on the examples invocation" {
            {
                Invoke-pwshake (Get-RelativePath "examples\4.complex\v1.0\complex_pwshake.yaml") `
                    @("create_linux_istance","deploy_shake") `
                    (Get-RelativePath "examples\4.complex\v1.0\metadata")
            } | Should -Not -Throw
        }

        It "Should not throw on the examples invocation of create_env_pwshake" {
            {
                Invoke-pwshake (Get-RelativePath "examples\4.complex\v1.0\create_env_pwshake.yaml") `
                    @("create_environment") `
                    (Get-RelativePath "examples\4.complex\v1.0\metadata")
            } | Should -Not -Throw
            $pwshake_log = Get-Content (Get-RelativePath "examples\4.complex\v1.0\create_env_pwshake.log")
            $pwshake_log | Select-String '] Here chef step\.' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Deploy role webui' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Here firewall rules for webui' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Deploy role api' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Here firewall rules for api' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Deploy role static' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String '] Here firewall rules for static' | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] $((Get-RelativePath 'examples\4.complex\v1.0\attributes_overrides\local.yaml').Replace('\','\\'))" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] 00000000-0000-0000-0000-000000000000" | Should -Not -BeNullOrEmpty
        }

        It 'Should not throw on the example invocation of nested includes' {
            {
                Invoke-pwshake (Get-RelativePath 'examples\4.complex\v1.0\module\pwshake.yaml') -Roles 'deep'
            } | Should -Not -Throw
            $pwshake_log = Get-Content (Get-RelativePath 'examples\4.complex\v1.0\module\pwshake.log')
            $pwshake_log | Select-String "] Hello from 'Deep buried role'" | Should -Not -BeNullOrEmpty
        }

        It 'Should throw on the example invocation of generated errors' {
            {
                Invoke-pwshake (Get-RelativePath 'examples\4.complex\v1.0\module\pwshake.yaml') -Roles 'errors' -Metadata @{py_arg='0'}
            } | Should -Throw 'ZeroDivisionError: division by zero'
            $pwshake_log = Get-Content (Get-RelativePath 'examples\4.complex\v1.0\module\pwshake.log')
            $pwshake_log | Select-String "] start0" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] noerr0" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] err0" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] ERROR: ZeroDivisionError: division by zero" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] Try call file: pwshake0" | Should -BeNullOrEmpty
        }

        It 'Should throw on the example invocation of Invoke-Command' {
            {
                Invoke-pwshake (Get-RelativePath 'examples\4.complex\v1.0\module\pwshake.yaml') -Roles 'errors' -Metadata @{pwsh_arg='42'}
            } | Should -Throw "The term 'dir42' is not recognized as the name of a cmdlet"
            $pwshake_log = Get-Content (Get-RelativePath 'examples\4.complex\v1.0\module\pwshake.log')
            $pwshake_log | Select-String "] Try call file: dir42" | Should -Not -BeNullOrEmpty
            $pwshake_log | Select-String "] ERROR: The term 'dir42' is not recognized as the name of a cmdlet" | Should -Not -BeNullOrEmpty
        }
    }
}
