$ErrorActionPreference = "Stop"

Context "Build-Config" {

    It "Should return a Hashtable" {
        @{} | Build-Config | Should -BeOfType [Hashtable]
    }

    It "Should return a full config structure" {
        $actual = @{} | Build-Config

        $actual.includes -is [Object[]] | Should -BeTrue
        $actual.attributes -is [Hashtable] | Should -BeTrue
        $actual.attributes_overrides -is [Object[]] | Should -BeTrue
        $actual.scripts_directories -is [Object[]] | Should -BeTrue
        $actual.tasks -is [Hashtable] | Should -BeTrue
        $actual.invoke_tasks -is [Object[]] | Should -BeTrue
    }
}
