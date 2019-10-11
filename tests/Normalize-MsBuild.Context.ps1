$ErrorActionPreference = "Stop"

Context "Normalize-MsBuild" {
    $msbuildPath = Get-RelativePath 'examples/example.msbuild.proj'

    It "Should return `$null on `$null " {
        Normalize-MsBuild $null | Should -BeNullOrEmpty
    }

    It "Should return an empty Hashtable" {
        $actual = Normalize-MsBuild @{}

        $actual | Should -BeOfType System.Collections.Hashtable
        $actual.Keys | Should -Contain "project"
        $actual.Keys | Should -Contain "targets"
        $actual.Keys | Should -Contain "properties"
        $actual.project | Should -BeNullOrEmpty
        $actual.targets | Should -BeNullOrEmpty
        $actual.properties | Should -BeNullOrEmpty
    }

    It "Should return $msbuildPath in 'project' key" {
        $actual = Normalize-MsBuild $msbuildPath

        $actual.project | Should -Be $msbuildPath
    }

    It "Should return $msbuildPath by given 'project' key" {
        $actual = Normalize-MsBuild @{project = $msbuildPath}

        $actual.project | Should -Be $msbuildPath
    }

    It "Should find path relative to $PWD" {
        $actual = Normalize-MsBuild 'pwshake.ps1'

        $actual.project | Should -Be "$(Resolve-Path 'pwshake.ps1')"
    }

    It "Should find path relative to $(Split-Path 'examples\example.msbuild.proj' -Parent)" {
        $actual = Normalize-MsBuild 'examples\example.msbuild.proj'

        $actual.project | Should -Be "$msbuildPath"
    }

    It "Should find absolute path to $(Resolve-Path 'examples\build.properties')" {
        $expected = "$(Resolve-Path 'examples\build.properties')"
        $actual = Normalize-MsBuild $expected

        $actual.project | Should -Be $expected
    }

    It "Should find project path relative to $PWD" {
        $actual = Normalize-MsBuild @{project = 'pwshake.ps1'}

        $actual.project | Should -Be "$(Resolve-Path 'pwshake.ps1')"
    }

    It "Should find project path relative to $(Split-Path 'examples\example.msbuild.proj' -Parent)" {
        $actual = Normalize-MsBuild @{project = 'examples\example.msbuild.proj'}

        $actual.project | Should -Be "$msbuildPath"
    }

    It "Should find project path relative to `$config.attributes.work_dir" {
        $actual = Normalize-MsBuild @{ project = 'example.msbuild.proj' } @{
            attributes = @{ work_dir = "$(Resolve-Path 'examples')" }
        }

        $actual.project | Should -Be "$msbuildPath"
    }

    It "Should find project path relative to `$config.attributes.pwshake_path" {
        $expected = "$(Resolve-Path 'examples\build.properties')"
        $actual = Normalize-MsBuild @{ project = 'build.properties' } @{
            attributes = @{ pwshake_path = "$(Resolve-Path 'examples')" }
        }

        $actual.project | Should -Be $expected
    }

    It "Should find absolute project path to $(Resolve-Path 'examples\build.properties')" {
        $expected = "$(Resolve-Path 'examples\build.properties')"
        $actual = Normalize-MsBuild @{ project = $expected }

        $actual.project | Should -Be $expected
    }

    It "Should return non empty Hashtable" {
        $actual = Normalize-MsBuild @{
            project = $msbuildPath;
            targets = "Mock";
            properties = "Configuration=Release";
        }

        $actual.project | Should -Be $msbuildPath
        $actual.targets | Should -Be "Mock"
        $actual.properties | Should -Be "Configuration=Release"
    }

    It "Should throw if project file does not exist" {
        {Normalize-MsBuild 'mock'} | Should -Throw 'Unknown path: mock'
    }

    It "Should normalize a full structure" {
        $mock = @"
project: $msbuildPath
targets: Mock
properties: Configuration=Release
"@ | ConvertFrom-Yaml
        $actual = Normalize-MsBuild $mock
        
        $actual.project | Should -Be $msbuildPath
        $actual.targets | Should -Be "Mock"
        $actual.properties | Should -Be "Configuration=Release"
    }
}
