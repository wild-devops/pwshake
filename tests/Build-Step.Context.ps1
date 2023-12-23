$ErrorActionPreference = "Stop"

Context "Build-Step" {
    BeforeAll {
        $scriptPath = "$PWD/tools/publish.ps1"

        function Ensure-Step {
            param(
                [hashtable]$actual,
                [string]$powershell = $null,
                [string]$name = 'step_*',
                [string]$when = '$true',
                [string]$work_dir = $null,
                [string]$on_error = 'throw'
            )
            process {
                # Write-Host "`$actual:`n$(cty $actual)"
                $actual | Should -BeOfType System.Collections.Hashtable
                $actual.Keys | Should -Contain "name"
                $actual.Keys | Should -Contain "when"
                $actual.Keys | Should -Contain "work_dir"
                $actual.Keys | Should -Contain "on_error"
                $actual.Keys | Should -Contain "powershell"
                $actual.name | Should -BeLike $name
                $actual.when | Should -Be $when
                if ($work_dir) {
                    $actual.work_dir | Should -Be $work_dir
                }
                else {
                    $actual.work_dir | Should -BeNullOrEmpty
                }
                $actual.on_error | Should -Be $on_error
                if ($powershell) {
                    $actual.powershell | Should -BeLike $powershell
                }
                else {
                    $actual.powershell | Should -BeNullOrEmpty
                }
            }
        }
    }

    It "Should return `$null on `$null " {
        Build-Step $null | Should -BeNullOrEmpty
    }

    It "Should return on empty Hashtable" {
        $actual = Build-Step @{}

        Ensure-Step $actual
    }

    It "Should return $scriptPath in 'script' key" {
        $actual = Build-Step $scriptPath

        Ensure-Step $actual '$paths = $config.scripts_directories | *' $scriptPath
        $actual.script | Should -Be $scriptPath
    }

    It "Should return $scriptPath by given 'script' key" {
        $actual = Build-Step @{script = $scriptPath }

        Ensure-Step $actual '$paths = $config.scripts_directories | *' -name 'script_*'
        $actual.script | Should -Be $scriptPath
    }

    It "Should find path relative to `$PWD" {
        $actual = Build-Step @{script = 'pwshake.ps1' }

        Ensure-Step $actual '$paths = $config.scripts_directories | *' -name 'script_*'
        $actual.script | Should -Be 'pwshake.ps1'
    }

    It "Should return non empty Hashtable" {
        $actual = Build-Step @{
            script = $scriptPath;
            name   = "Mock";
        }

        Ensure-Step $actual '$paths = $config.scripts_directories | *' 'Mock'
        $actual.script | Should -Be $scriptPath
    }

    It "Should normalize a full structure" {
        $mock = @"
name: Mock
powershell: pwsh
"@ | f-cfy
        $actual = Build-Step $mock

        Ensure-Step $actual 'pwsh' 'Mock'
    }

    It "Should normalize a single string as 'script' and 'name' keys" {
        $mock = (@"
run_list:
- Mock
"@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual '$paths = $config.scripts_directories | *' 'Mock'
        $actual.script | Should -Be "Mock"
    }

    It "Should normalize a 'powershell' key with default 'name'" {
        $mock = (@"
run_list:
- powershell: Mock
"@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual 'Mock' -name 'powershell_*'
    }

    It "Should normalize a 'cmd' key with default 'name'" {
        $mock = (@"
run_list:
- cmd: Mock
"@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual 'Cmd-Shell "$($_.cmd -split*' -name 'cmd_*'
        $actual.cmd | Should -Be 'Mock'
    }

    It "Should normalize named key with an implicit 'name'" {
        $mock = (@"
run_list:
- mock me:
    powershell: Mock
"@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual 'Mock' 'mock me'
    }

    It "Should normalize named key with an implicit 'name' and alias" {
        $mock = (@"
run_list:
- mock me:
    pwsh: Mock
"@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual 'Mock' 'mock me'
    }

    It "Should normalize named key with an implicit 'name' and template" {
        $mock = (@"
run_list:
- mock me:
    cmd: Mock
"@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual 'Cmd-Shell "$($_.cmd -split*' 'mock me'
        $actual.cmd | Should -Be 'Mock'
    }

    It "Should normalize implicit step with explicit 'name' and template" {
        $mock = (@"
run_list:
- name: mock me
  cmd: Mock
"@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual 'Cmd-Shell "$($_.cmd -split*' 'mock me'
        $actual.cmd | Should -Be 'Mock'
    }

    It "Should normalize full step with an explicit 'name'" {
        $mock = (@"
run_list:
- step:
    name: mock me
    powershell: Mock
"@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual 'Mock' 'mock me'
    }

    It "Should normalize implicit step with an explicit 'name'" {
        $mock = (@"
run_list:
- name: mock me
  powershell: Mock
"@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual 'Mock' 'mock me'
    }

    It "Should normalize implicit step with an explicit 'name' and alias" {
        $mock = (@"
run_list:
- name: mock me
  pwsh: Mock
"@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual 'Mock' 'mock me'
    }

    It "Should normalize implicit step with an explicit attributes" {
        $mock = (@'
run_list:
- name: mock me
  when: $false
  work_dir: ./
  on_error: continue
  powershell: Mock
'@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual 'Mock' -name 'mock me' -when '$false' -work_dir './' -on_error 'continue'
    }

    It "Should normalize explicit step with an explicit attributes" {
        $mock = (@'
run_list:
- 'mock me':
    when: $false
    work_dir: ./
    on_error: continue
    powershell: Mock
'@ | f-cfy).run_list | Select-Object -First 1
        $actual = Build-Step $mock

        Ensure-Step $actual 'Mock' -name 'mock me' -when '$false' -work_dir './' -on_error 'continue'
    }
}
