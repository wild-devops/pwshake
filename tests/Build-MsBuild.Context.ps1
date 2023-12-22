$ErrorActionPreference = "Stop"

Context "Build-MsBuild" {
    BeforeAll {
        $msbuildPath = Join-Path $PSScriptRoot\.. -ChildPath 'examples/5.templates/example.msbuild.proj'
    }

    It "Should return `$null on `$null " {
        Build-Step $null | Should -BeNullOrEmpty
    }

    It "Should return a full step structure with default template items" {
        $actual = Build-Step ("msbuild:" | ConvertFrom-Yaml -AsHashTable)

        $actual | Should -BeOfType System.Collections.Hashtable
        $actual.Keys | Should -Contain "msbuild"
        $actual.Keys | Should -Contain "project"
        $actual.Keys | Should -Contain "targets"
        $actual.Keys | Should -Contain "properties"
        $actual.Keys | Should -Contain "options"
        $actual.Keys | Should -Contain "name"
        $actual.Keys | Should -Contain "when"
        $actual.Keys | Should -Contain "work_dir"
        $actual.Keys | Should -Contain "on_error"
        $actual.Keys | Should -Contain "powershell"
        $actual.name        | Should -BeLike "msbuild_*"
        $actual.when        | Should -Be '$true'
        $actual.work_dir    | Should -BeNullOrEmpty
        $actual.on_error    | Should -Be 'throw'
        $actual.powershell  | Should -BeLike "`$cmd = if (`${is-Linux}) {'dotnet msbuild'}*"
        $actual.msbuild     | Should -BeNullOrEmpty
        $actual.project     | Should -BeLike '*/version*'
        $actual.targets     | Should -BeNullOrEmpty
        $actual.properties  | Should -BeNullOrEmpty
        $actual.options     | Should -BeNullOrEmpty
    }

    It "Should return $msbuildPath in 'msbuild' key" {
        $actual = Build-Step ("msbuild: $msbuildPath" | ConvertFrom-Yaml -AsHashTable)

        $actual.project | Should -Be $msbuildPath
    }

    It "Should return $msbuildPath by given 'project' key" {
        $actual = Build-Step ("msbuild:`n  project: $msbuildPath" | ConvertFrom-Yaml -AsHashTable)

        $actual.project | Should -Be $msbuildPath
    }

    It "Should normalize a full structure" {
        $actual = Build-Step (@"
        msbuild:
          project: $msbuildPath
          targets:
          - Mock1
          - Mock2
          properties:
          - Configuration=Release1
          - Configuration=Release2
          options:
          - Option1
          - Option2
"@ | ConvertFrom-Yaml -AsHashTable)

        $actual.project | Should -Be $msbuildPath
        "$($actual.targets)" | Should -Be "Mock1 Mock2"
        "$($actual.properties)" | Should -Be "Configuration=Release1 Configuration=Release2"
        "$($actual.options)" | Should -Be "Option1 Option2"
    }

    It "Should throw if project file does not exist" {
        { "msbuild: mock1" | ConvertFrom-Yaml -AsHashTable | Invoke-Step } | Should -Throw 'Unknown path: mock1'
        { "msbuild:`n  project: mock2" | ConvertFrom-Yaml -AsHashTable | Invoke-Step } | Should -Throw 'Unknown path: mock2'
    }
}
