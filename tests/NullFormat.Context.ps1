$ErrorActionPreference = "Stop"

Context "NullFormat" {
    $context = @{
        value='expected'
        format=' -f $_'
    }
    $expected=' -f expected'

    It "Should return `$null on `$null" {
        (NullFormat) | Should -BeNullOrEmpty
    }
    
    It "Should return `$null  from argument" {
        (NullFormat $null) | Should -BeNullOrEmpty
    }
    
    It "Should return `$null from pipeline" {
        ($null | NullFormat) | Should -BeNullOrEmpty
    }

    It "Should return `$value from argument" {
        (NullFormat $context.value) | Should -Be 'expected'
    }

    It "Should return `$value from pipeline" {
        ($context.value | NullFormat) | Should -Be 'expected'
    }

    It "Should return flag from arguments" {
        (NullFormat @context) | Should -Be $expected
    }    

    It "Should return flag from pipeline" {
        ($context.value | NullFormat -f $context.format) | Should -Be $expected
    }
}
