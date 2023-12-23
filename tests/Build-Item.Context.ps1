$ErrorActionPreference = "Stop"

Context "Build-Item" {

  BeforeAll {
    $reserved_keys = (@{msbuild = ''; pwsh = '' }).Keys
    $config = @{attributes = @{
        pwshake_verbosity = 'Default'
        pwshake_log_path  = "$PWD/pwshake.log"
      }
    }

    function Ensure-Item {
      param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$item,
        $count = 1,
        $name,
        [scriptblock]$sb = {}
      )
      process {
        $item | Should -Not -BeNullOrEmpty
        $item | Should -BeOfType [hashtable]
        $item.Keys.Count | Should -Be $count
        $item.Keys | Should -Contain 'name'
        $item.name | Should -BeLike $name
        & $sb $item
      }
    }
  }

  It "Should return `$null on `$null " {
    Build-Item $null -reserved-keys $reserved_keys | Should -BeNullOrEmpty
  }

  It "Should normalize a simple name" {
    $mock = @"
        steps:
        - Mock:
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Mock'
  }

  It "Should normalize a simple name with payload" {
    $mock = @"
        steps:
        - Mock: payload
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Mock' -count 2 -sb { param($actual)
      $actual.$($actual.name) | Should -Be 'payload'
    }
  }

  It "Should normalize a simple name with simple payload" {
    $mock = @"
        steps:
        - Mock:
            msbuild:
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Mock' -count 2 -sb { param($actual)
      $actual.msbuild | Should -BeNullOrEmpty
    }
  }

  It "Should normalize a simple name with complex payload" {
    $mock = @"
        steps:
        - Mock:
            msbuild: payload.csproj
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Mock' -count 2 -sb { param($actual)
      $actual.msbuild | Should -Be 'payload.csproj'
    }
  }

  It "Should normalize a long name" {
    $mock = @"
        steps:
        - Mock me:
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Mock me'
  }

  It "Should normalize a long name with payload" {
    $mock = @"
        steps:
        - Mock me: payload
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Mock me' -count 2 -sb { param($actual)
      $actual.$($actual.name) | Should -Be 'payload'
    }
  }

  It "Should normalize a long name with simple payload" {
    $mock = @"
        steps:
        - Mock me:
            msbuild:
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Mock me' -count 2 -sb { param($actual)
      $actual.msbuild | Should -BeNullOrEmpty
    }
  }

  It "Should normalize a long name with complex payload" {
    $mock = @"
        steps:
        - Mock me:
            msbuild: payload.csproj
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Mock me' -count 2 -sb { param($actual)
      $actual.msbuild | Should -Be 'payload.csproj'
    }
  }

  It "Should normalize a long name with full payload" {
    $mock = @"
        steps:
        - Full payload:
            msbuild:
              project: payload.csproj
              targets:
              - Clean
              - Build
              - Test
            other:
              deep: payload
              deeper:
                - payload1
                - payload2
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Full payload' -count 3 -sb { param($actual)
      $actual.msbuild | Should -BeOfType [hashtable]
      $actual.msbuild.project | Should -Be 'payload.csproj'
      $actual.msbuild.targets.Count | Should -Be 3
      $actual.msbuild.targets[0] | Should -Be 'Clean'
      $actual.msbuild.targets[1] | Should -Be 'Build'
      $actual.msbuild.targets[2] | Should -Be 'Test'
      $actual.other | Should -BeOfType [hashtable]
      $actual.other.deep | Should -Be 'payload'
      $actual.other.deeper.Count | Should -Be 2
      $actual.other.deeper[0] | Should -Be 'payload1'
      $actual.other.deeper[1] | Should -Be 'payload2'
    }
  }

  It "Should normalize just a template implicit name" {
    $mock = @"
        steps:
        - msbuild:
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'msbuild_*' -count 2 -sb { param($actual)
      $actual.msbuild | Should -BeNullOrEmpty
    }
  }

  It "Should normalize just a template with explicit name" {
    $mock = @"
        steps:
        - msbuild:
          name: Build it all
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Build it all' -count 2 -sb { param($actual)
      $actual.msbuild | Should -BeNullOrEmpty
    }
  }

  It "Should normalize just a template witn implicit name and payload" {
    $mock = @"
        steps:
        - msbuild: payload.csproj
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'msbuild_*' -count 2 -sb { param($actual)
      $actual.msbuild | Should -Be 'payload.csproj'
    }
  }

  It "Should normalize just a template with explicit name and payload" {
    $mock = @"
        steps:
        - msbuild: payload.csproj
          name: Build it all
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Build it all' -count 2 -sb { param($actual)
      $actual.msbuild | Should -Be 'payload.csproj'
    }
  }

  It "Should normalize an explicit long name with full payload" {
    $mock = @"
        steps:
        - name: Build it all
          msbuild:
            project: payload.csproj
            targets:
            - Clean
            - Build
            - Test
          other:
            deep: payload
            deeper:
              - payload1
              - payload2
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Build it all' -count 3 -sb { param($actual)
      $actual.msbuild | Should -BeOfType [hashtable]
      $actual.msbuild.project | Should -Be 'payload.csproj'
      $actual.msbuild.targets.Count | Should -Be 3
      $actual.msbuild.targets[0] | Should -Be 'Clean'
      $actual.msbuild.targets[1] | Should -Be 'Build'
      $actual.msbuild.targets[2] | Should -Be 'Test'
      $actual.other | Should -BeOfType [hashtable]
      $actual.other.deep | Should -Be 'payload'
      $actual.other.deeper.Count | Should -Be 2
      $actual.other.deeper[0] | Should -Be 'payload1'
      $actual.other.deeper[1] | Should -Be 'payload2'
    }
  }

  It "Should override an explicit long name over implicit one" {
    $mock = @"
        steps:
        - Implicit name:
            name: Build it all
            msbuild:
              project: payload.csproj
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'Build it all' -count 2 -sb { param($actual)
      $actual.msbuild | Should -BeOfType [hashtable]
      $actual.msbuild.project | Should -Be 'payload.csproj'
    }
  }

  It "Should assign implicit step name" {
    $mock = @"
        steps:
        - pwsh: echo 42
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1

    $mock | Build-Item -config $config -reserved-keys $reserved_keys `
    | Ensure-Item -name 'pwsh_*' -count 2 -sb { param($actual)
      $actual.powershell | Should -Be 'echo 42'
    }
  }
}
