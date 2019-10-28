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
        $actual.Keys | Should -Contain "when"
        $actual.Keys | Should -Contain "work_dir"
        $actual.Keys | Should -Contain "on_error"
        $actual.Keys | Should -Contain "powershell"
        $actual.name | Should -BeLike "step_*"
        $actual.when | Should -Be '$true'
        $actual.work_dir | Should -BeNullOrEmpty
        $actual.on_error | Should -Be 'throw'
        $actual.powershell | Should -BeNullOrEmpty
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
powershell: pwsh
"@ | ConvertFrom-Yaml
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "Mock"
        $actual.powershell | Should -Be "pwsh"
    }

    It "Should normalize a single string as 'script' and 'name' keys" {
        $mock = (@"
run_list:
- Mock
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "Mock"
        $actual.script | Should -Be "Mock"
        $actual.powershell | Should -Not -BeNullOrEmpty
    }

    It "Should normalize a 'powershell' key with default 'name'" {
        $mock = (@"
run_list:
- powershell: Mock
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -BeLike "step_*"
        $actual.powershell | Should -Be "Mock"
    }

    It "Should normalize a 'cmd' key with default 'name'" {
        $mock = (@"
run_list:
- cmd: Mock
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -BeLike "step_*"
        $actual.powershell | Should -Not -BeNullOrEmpty
        $actual.cmd | Should -Be "Mock"
    }

    It "Should normalize named key with an implicit 'name'" {
        $mock = (@"
run_list:
- mock:
    powershell: Mock    
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "mock"
        $actual.powershell | Should -Be "Mock"
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
        $actual.powershell | Should -Be "Mock"
    }

    It "Should normalize implicit step with an explicit 'name'" {
        $mock = (@"
run_list:
- name: mock    
  powershell: Mock    
"@ | ConvertFrom-Yaml).run_list | Select-Object -First 1
        $actual = Normalize-Step $mock
        
        $actual.name | Should -Be "mock"
        $actual.powershell | Should -Be "Mock"
    }
}
