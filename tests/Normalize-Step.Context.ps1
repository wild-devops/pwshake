$ErrorActionPreference = "Stop"

Context "Normalize-Step" {
    $scriptPath = Get-RelativePath 'tools/publish.ps1'

    It "Should return `$null on `$null " {
        Normalize-Step $null | Should -BeNullOrEmpty
    }

    It "Should return an empty Hashtable" {
        $actual = Normalize-Step @{}

        $actual | Should -BeOfType System.Collections.Hashtable
        $actual.Keys | Should -Contain "name"
        $actual.Keys | Should -Contain "script"
        $actual.Keys | Should -Contain "powershell"
        $actual.Keys | Should -Contain "cmd"
        $actual.Keys | Should -Contain "msbuild"
        $actual.name | Should -BeLike "step_*"
        $actual.script | Should -BeNullOrEmpty
        $actual.powershell | Should -BeNullOrEmpty
        $actual.cmd | Should -BeNullOrEmpty
        $actual.msbuild | Should -BeNullOrEmpty
    }

    It "Should return $scriptPath in 'script' key" {
        $actual = Normalize-Step $scriptPath

        $actual.script | Should -Be $scriptPath
    }

    It "Should return $scriptPath by given 'script' key" {
        $actual = Normalize-Step @{script = $scriptPath}

        $actual.script | Should -Be $scriptPath
    }

    It "Should find path relative to `$PWD" {
        $actual = Normalize-Step @{script = 'pwshake.ps1'}

        $actual.script | Should -Be 'pwshake.ps1'
    }

    It "Should return non empty Hashtable" {
        $actual = Normalize-Step @{
            script = $scriptPath;
            name = "Mock";
        }

        $actual.script | Should -Be $scriptPath
        $actual.name | Should -Be "Mock"
    }

    It "Should normalize a full structure" {
        $mock = @"
name: Mock
script: $scriptPath
powershell: pwsh
cmd: python.exe
msbuild: $scriptPath
"@ | ConvertFrom-Yaml
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "Mock"
        $actual.script | Should -Be $scriptPath
        $actual.powershell | Should -Be "pwsh"
        $actual.cmd | Should -Be "python.exe"
        $actual.msbuild.project | Should -Be $scriptPath
    }

    It "Should normalize a single string as 'script' and 'name' keys" {
        $mock = (@"
run_list:
- Mock
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "Mock"
        $actual.script | Should -Be "Mock"
        $actual.powershell | Should -BeNullOrEmpty
        $actual.cmd | Should -BeNullOrEmpty
        $actual.msbuild.project | Should -BeNullOrEmpty
    }

    It "Should normalize a 'powershell' key with default 'name'" {
        $mock = (@"
run_list:
- powershell: Mock
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -BeLike "step_*"
        $actual.script | Should -BeNullOrEmpty
        $actual.powershell | Should -Be "Mock"
        $actual.cmd | Should -BeNullOrEmpty
        $actual.msbuild.project | Should -BeNullOrEmpty
    }

    It "Should normalize a 'cmd' key with default 'name'" {
        $mock = (@"
run_list:
- cmd: Mock
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -BeLike "step_*"
        $actual.script | Should -BeNullOrEmpty
        $actual.powershell | Should -BeNullOrEmpty
        $actual.cmd | Should -Be "Mock"
        $actual.msbuild.project | Should -BeNullOrEmpty
    }

    It "Should normalize a 'msbuild' key with default 'name'" {
        $mock = (@"
run_list:
- msbuild: $scriptPath
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -BeLike "step_*"
        $actual.script | Should -BeNullOrEmpty
        $actual.powershell | Should -BeNullOrEmpty
        $actual.cmd | Should -BeNullOrEmpty
        $actual.msbuild.project | Should -Be $scriptPath
    }

    It "Should normalize a 'msbuild' key with implicit 'name'" {
        $mock = (@"
run_list:
- step:
    msbuild: $scriptPath
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "step"
        $actual.script | Should -BeNullOrEmpty
        $actual.powershell | Should -BeNullOrEmpty
        $actual.cmd | Should -BeNullOrEmpty
        $actual.msbuild.project | Should -Be $scriptPath
    }

    It "Should normalize a 'msbuild' key with explicit 'name'" {
        $mock = (@"
run_list:
- name: msbuild1
  msbuild: $scriptPath
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "msbuild1"
        $actual.script | Should -BeNullOrEmpty
        $actual.powershell | Should -BeNullOrEmpty
        $actual.cmd | Should -BeNullOrEmpty
        $actual.msbuild.project | Should -Be $scriptPath
    }

    It "Should normalize a 'msbuild' step with full structure" {
        $mock = (@"
run_list:
- step:
    name: msbuild_full
    msbuild:
      project: $scriptPath
      targets: Mock
      properties: Configuration=Release
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "msbuild_full"
        $actual.script | Should -BeNullOrEmpty
        $actual.powershell | Should -BeNullOrEmpty
        $actual.cmd | Should -BeNullOrEmpty
        $actual.msbuild.project | Should -Be $scriptPath
        $actual.msbuild.targets | Should -Be "Mock"
        $actual.msbuild.properties | Should -Be "Configuration=Release"
    }

    It "Should normalize an implicit step with 'msbuild' key and explicit 'name'" {
        $mock = (@"
run_list:
- step:
    name: msbuild2
    msbuild: $scriptPath
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "msbuild2"
        $actual.script | Should -BeNullOrEmpty
        $actual.powershell | Should -BeNullOrEmpty
        $actual.cmd | Should -BeNullOrEmpty
        $actual.msbuild.project | Should -Be $scriptPath
    }

    It "Should normalize named key with an implicit 'name'" {
        $mock = (@"
run_list:
- mock:
    powershell: Mock    
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "mock"
        $actual.script | Should -BeNullOrEmpty
        $actual.powershell | Should -Be "Mock"
        $actual.cmd | Should -BeNullOrEmpty
        $actual.msbuild.project | Should -BeNullOrEmpty
    }

    It "Should normalize full step with an explicit 'name'" {
        $mock = (@"
run_list:
- step:
    name: mock    
    powershell: Mock    
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "mock"
        $actual.script | Should -BeNullOrEmpty
        $actual.powershell | Should -Be "Mock"
        $actual.cmd | Should -BeNullOrEmpty
        $actual.msbuild.project | Should -BeNullOrEmpty
    }

    It "Should normalize implicit step with an explicit 'name'" {
        $mock = (@"
run_list:
- name: mock    
  powershell: Mock    
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "mock"
        $actual.script | Should -BeNullOrEmpty
        $actual.powershell | Should -Be "Mock"
        $actual.cmd | Should -BeNullOrEmpty
        $actual.msbuild.project | Should -BeNullOrEmpty
    }
}
