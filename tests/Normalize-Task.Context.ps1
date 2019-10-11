$ErrorActionPreference = "Stop"

Context "Normalize-Task" {

    It "Should return default runlist on `$null " {
        $actual = Normalize-Task $null
        
        $actual | Should -BeOfType System.Collections.Hashtable
        $actual.name -match 'task_\d+' | Should -BeTrue
        $actual.steps | Should -Be @()
        $actual.depends_on | Should -Be @()
        $actual.when | Should -Be "`$true"
    }

    It "Should normalize an empty structure" {
      $mock = @"
tasks:
  Mock:
"@ | ConvertFrom-Yaml
      $key = $mock.tasks.Keys | Select-Object -First 1
      $actual = Normalize-Task $mock.tasks[$key] $key

      $actual.name | Should -Be 'Mock'
      $actual.steps.Count | Should -Be 0
      $actual.depends_on.Count | Should -Be 0
      $actual.when | Should -Be "`$true"
  }

    It "Should normalize when: aliases" {
      $mock = @"
tasks:
  Mock1:
    only: "only"  
  Mock2:
    except: "except"  
  Mock3:
    skip_on: "skip_on"  
"@ | ConvertFrom-Yaml
      foreach ($key in $mock.tasks.Keys) {
        $actual = Normalize-Task $mock.tasks[$key] $key

        $actual.name | Should -Be $key
        $actual.steps.Count | Should -Be 0
        $actual.depends_on.Count | Should -Be 0
        $when = "only"
        if ($mock.tasks[$key].except) {
          $when = "-not (except)"
        } elseif ($mock.tasks[$key].skip_on) {
          $when = "-not (skip_on)"
        }
        $actual.when | Should -Be $when
      }
  }

    It "Should normalize a full structure" {
        $mock = @"
name: Mock
depends_on:
  - Mock
scripts:
  - Mock
when: 1 -eq 2
"@ | ConvertFrom-Yaml
        $actual = Normalize-Task $mock
        
        $actual.name | Should -Be 'Mock'
        $actual.steps.Count | Should -Be 1
        $actual.steps | Should -Contain 'Mock'
        $actual.depends_on.Count | Should -Be 1
        $actual.depends_on | Should -Contain 'Mock'
        $actual.when | Should -Be "1 -eq 2"
    }

    It "Should normalize partial structure" {
        $mock = @"
tasks:
  Mock:
    depends_on:
      - Mock
    scripts:
      - Mock
"@ | ConvertFrom-Yaml
        $key = $mock.tasks.Keys | Select-Object -First 1
        $actual = Normalize-Task $mock.tasks[$key] $key
        
        $actual.name | Should -Be 'Mock'
        $actual.steps.Count | Should -Be 1
        $actual.steps | Should -Contain 'Mock'
        $actual.depends_on.Count | Should -Be 1
        $actual.depends_on | Should -Contain 'Mock'
        $actual.when | Should -Be "`$true"
    }

    It "Should normalize just a scripts array" {
        $mock = @"
tasks:
  Mock:
    - Mock1
    - Mock2
"@ | ConvertFrom-Yaml

        $key = $mock.tasks.Keys | Select-Object -First 1
        $actual = Normalize-Task $mock.tasks[$key] $key
        
        $actual.name | Should -Be 'Mock'
        $actual.steps.Count | Should -Be 2
        $actual.steps[0] | Should -Be 'Mock1'
        $actual.steps[1] | Should -Be 'Mock2'
        $actual.depends_on.Count | Should -Be 0
        $actual.when | Should -Be "`$true"
    }
}
