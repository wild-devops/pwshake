$ErrorActionPreference = "Stop"

Context "Normalize-Config" {

    It "Should return a Hashtable" {
        @{} | Normalize-Config | Should -BeOfType [Hashtable]
    }

    It "Should return a full config structure" {
        $actual = @{} | Normalize-Config
        
        $actual.includes -is [Object[]] | Should -BeTrue
        $actual.attributes -is [Hashtable] | Should -BeTrue
        $actual.attributes_overrides -is [Object[]] | Should -BeTrue
        $actual.scripts_directories -is [Object[]] | Should -BeTrue
        $actual.tasks -is [Hashtable] | Should -BeTrue
        $actual.invoke_tasks -is [Object[]] | Should -BeTrue
    }
}
