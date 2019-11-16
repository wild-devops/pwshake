$ErrorActionPreference = "Stop"

Context "Coalesce" {
    $context = @{
        existed='existed'
        expected='Mock'
        array=@('one')
        hashtable=@{'four'='two+two'}
    }

    It "Should return `$null on `$null" {
        (Coalesce $null) | Should -BeNullOrEmpty
    }

    It "Should return `$null on all `$null-s" {
        (Coalesce $context.actual, $context.does_not_exist, $null) | Should -BeNullOrEmpty
    }

    It "Should return a string" {
        (Coalesce $context.actual, $context.does_not_exist, $context.expected) | Should -Be 'Mock'
    }

    It "Should return the first string" {
        $context.existed | Should -Be 'existed'
        (Coalesce $context.actual, $context.expected, $context.existed) | Should -Be 'Mock'
    }

    It "Should return an array" {
        $context.existed | Should -Be 'existed'
        (Coalesce $context.actual, $context.does_not_exist, $context.array, $context.existed) | Should -Be @('one')
    }

    It "Should return a hashtable" {
        $context.existed | Should -Be 'existed'
        $context.array | Should -Be @('one')
        $actual = (Coalesce $context.actual, $context.does_not_exist, $context.hashtable, $context.array, $context.existed)
        $actual | Should -BeOfType [hashtable]
        $actual.Keys.Count | Should -Be 1
        "$($actual.Keys)" | Should -Be 'four'
        $actual.four | Should -Be 'two+two'
    }
}
