$ErrorActionPreference = "Stop"

Context "Log-Output" {

    $config = @{
        attributes = @{
            pwshake_log_path = "TestDrive:\mock.log"
        }
    }

    $files = @("TestDrive:\mock.log", "TestDrive:\mock.log.json" )

    BeforeEach {
        $files | ForEach-Object { New-Item -Path $_ -ItemType File -Force }
    }

    It "Should write `$null on `$null" {
        $null | Log-Output -c $config 6>&1 | Should -BeNullOrEmpty

        $files | ForEach-Object {
            Test-Path $_ | Should -BeTrue
            Get-Content $_ -Raw | Should -BeNullOrEmpty
        }
    }

    It "Should write 'mock' on 'mock' with timestamp" {
        'mock' | Log-Output -c $config 6>&1 | Should -Be 'mock'

        Get-Content "TestDrive:\mock.log" -Raw | Should -BeLike "*] mock$([Environment]::NewLine)"
        Get-Content "TestDrive:\mock.log.json" -Raw | Should -BeNullOrEmpty
    }
}
