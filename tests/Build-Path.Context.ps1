$ErrorActionPreference = "Stop"

Context "Build-Path" {
    BeforeAll {
        $config = @{
            attributes = @{
                work_dir         = "$PWD/tests"
                pwshake_path     = "$PWD/pwshake"
                pwshake_log_path = "TestDrive:/mock.log"
            }
        }
    }

    It "Should return `$null on `$null or empty string" {
        $null | Build-Path | Should -BeNullOrEmpty
        ''    | Build-Path | Should -BeNullOrEmpty
    }

    It "Should return a string" {
        '.' | Build-Path -config $config | Should -BeOfType [string]
    }

    It "Should return '$PWD' on '.'" {
        '.' | Build-Path -config $config | Should -Be "$PWD"
    }

    It "Should return existing path relative to '$PWD'" {
        'examples' | Build-Path -config $config | Should -Be ("$PWD/examples" | f-cnvp)
    }

    It "Should return unresolved path relative to 'pwshake_path:'" {
        'mock' | Build-Path -config $config -Unresolved | Should -Be ("$PWD/pwshake/mock" | f-cnvp)
    }

    It "Should throw on unexisting path relative to '$PWD'" {
        { 'mock' | Build-Path -config $config } | Should -Throw 'Unknown path: mock'
    }

    It "Should return existing path relative to 'work_dir:'" {
        'pwshake.Tests.ps1' | Build-Path -config $config | Should -Be ("$PWD/tests/pwshake.Tests.ps1" | f-cnvp)
    }

    It "Should return existing path relative to 'pwshake_path:'" {
        'pwshake.psm1' | Build-Path -config $config | Should -Be ("$PWD/pwshake/pwshake.psm1" | f-cnvp)
    }

    It "Should throw on unexisting path relative to 'work_dir:' or 'pwshake_path:'" {
        { 'mock' | Build-Path -config $config } | Should -Throw 'Unknown path: mock'
    }

    It "Should return existing absolute path" {
        "$PWD/tests/pwshake.Tests.ps1" | Build-Path -config $config | Should -Be ("$PWD/tests/pwshake.Tests.ps1" | f-cnvp)
        "$PWD/pwshake/pwshake.psm1" | Build-Path -config $config | Should -Be ("$PWD/pwshake/pwshake.psm1" | f-cnvp)
    }

    It "Should throw on unexisting absolute path" {
        { "$PWD/pwshake/mock" | Build-Path -config $config } | Should -Throw "Unknown path: $PWD/pwshake/mock"
    }

    It "Should return unresolved absolute path" {
        "$PWD/pwshake/mock" | Build-Path -config $config -Unresolved | Should -Be ("$PWD/pwshake/mock" | f-cnvp)
    }
}
