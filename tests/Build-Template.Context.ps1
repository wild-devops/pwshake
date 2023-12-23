$ErrorActionPreference = "Stop"

Context "Build-Template" {
  
  BeforeAll {
    function Ensure-Template {
      param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$actual,
        [hashtable]$expected = @{},
        [scriptblock]$sb = $null
      )
      process {
        $actual | Should -Not -BeNullOrEmpty
        $actual | Should -BeOfType [hashtable]
        if ($expected.Keys.Count) {
          $actual.Keys.Count | Should -Be $expected.Keys.Count
        }
        if ($null -ne $sb) {
          & $sb $actual
          return
        }
        foreach ($key in $expected.Keys) {
          if ($expected.$($key) -match '\*$') {
            $actual.$($key) |  Should -BeLike $expected.$($key)
          }
          elseif ($null -eq $expected.$($key)) {
            $actual.$($key) |  Should -BeNullOrEmpty
          }
          elseif ($expected.$($key) -is [hashtable]) {
          (cty $actual.$($key)) |  Should -Be (cty $expected.$($key))
          }
          else {
            $actual.$($key) |  Should -Be $expected.$($key)
          }
        }
      }
    }
  }

  It "Should return `$null on `$null " {
    Build-Template $null | Should -BeNullOrEmpty
  }

  It "Should normalize an empty simple template" {
    @'
      steps:
      - echo:
'@  | f-cfy | ForEach-Object steps | Select-Object -First 1 | `
      Build-Template | Ensure-Template -expected @{
      powershell = 'if ($_.echo -match*'
      echo       = $null
      '$context' = @{template_key = 'echo' }
    }
  }

  It "Should normalize simple template with payload" {
    @'
        steps:
        - echo: payload
'@  | f-cfy | ForEach-Object steps | Select-Object -First 1 | `
      Build-Template | Ensure-Template -expected @{
      powershell = 'if ($_.echo -match*'
      echo       = 'payload'
      '$context' = @{template_key = 'echo' }
    }
  }

  It "Should normalize simple template with payload and explicit name" {
    @'
      steps:
      - echo: something
        name: Say something, Mia
'@  | f-cfy | ForEach-Object steps | Select-Object -First 1 | `
      Build-Template | Ensure-Template -expected @{
      powershell = 'if ($_.echo -match*'
      echo       = 'something'
      name       = 'Say something, Mia'
      '$context' = @{template_key = 'echo' }
    }
  }

  It "Should normalize an empty complex template" {
    @"
      steps:
      - msbuild:
"@  | f-cfy | ForEach-Object steps | Select-Object -First 1 | `
      Build-Template | Ensure-Template -expected @{
      powershell = '$cmd = if (${is-Linux})*'
      msbuild    = $null
      project    = '*/version*'
      targets    = $null
      properties = $null
      options    = $null
      '$context' = @{template_key = 'msbuild' }
    }
  }

  It "Should normalize an empty complex template with payload" {
    @'
      steps:
      - msbuild: payload.csproj
'@  | f-cfy | ForEach-Object steps | Select-Object -First 1 | `
      Build-Template | Ensure-Template -expected @{
      powershell = '$cmd = if (${is-Linux})*'
      msbuild    = 'payload.csproj'
      project    = 'payload.csproj'
      targets    = $null
      properties = $null
      options    = $null
      '$context' = @{template_key = 'msbuild' }
    }
  }

  It "Should normalize a complex template with payload and name" {
    @'
      steps:
      - msbuild: payload.csproj
        name: Build it all
'@  | f-cfy | ForEach-Object steps | Select-Object -First 1 | `
      Build-Template | Ensure-Template -expected @{
      name       = 'Build it all'
      powershell = '$cmd = if (${is-Linux})*'
      msbuild    = 'payload.csproj'
      project    = 'payload.csproj'
      targets    = $null
      properties = $null
      options    = $null
      '$context' = @{template_key = 'msbuild' }
    }
  }

  It "Should normalize nested template" {
    @'
      steps:
      - on_error: continue
        invoke_steps:
        - echo: say
        - invoke_steps:
          - echo: hello
'@  | f-cfy | ForEach-Object steps | Select-Object -First 1 | `
      Build-Template | Ensure-Template -sb { param($actual)
      $actual.on_error | Should -Be 'continue'
      $actual.powershell | Should -BeLike '$_.invoke_steps | Invoke-Step'
      $actual.invoke_steps[0].echo | Should -Be 'say'
      $actual.invoke_steps[1].invoke_steps[0].echo | Should -Be 'hello'
      $actual['$context'].template_key | Should -Be 'invoke_steps'
    }
  }

  It "Should normalize nested template with context evaluation" {
    @'
      steps:
      - each:
          items: $[[$each.context]]
          action:
            echo: '[[.Key]] files: [[.ListOfFiles]]'
          context:
            Key: PWSHAKE
            Value: '[[.Key]]'
            Files:
            - '[[.Key]].txt'
            - '[[.Key]].log'
            - '[[.Key]].key'
            ListOfFiles: '[[$("$($_.Files)")]]'
            AppService:
              Locations: '[[.Files]]'
              Executable: '[[.Key]]\[[.Value]].exe'
'@  | f-cfy | ForEach-Object steps | ForEach-Object {
      $_.each.context | Interpolate-Item -step ($_ | Build-Template) | Ensure-Template -sb { param($actual)
        $actual.powershell | Should -BeLike 'if (-not $each.items) { throw*'
        $actual.items.Key | Should -Be 'PWSHAKE'
        $actual.items.Value | Should -Be 'PWSHAKE'
        $actual.items.Files | Should -Be @('PWSHAKE.txt', 'PWSHAKE.log', 'PWSHAKE.key')
        $actual.items.ListOfFiles | Should -Be 'PWSHAKE.txt PWSHAKE.log PWSHAKE.key'
        $actual.items.AppService.Locations | Should -Be @('PWSHAKE.txt', 'PWSHAKE.log', 'PWSHAKE.key')
        $actual.items.AppService.Executable | Should -Be 'PWSHAKE\PWSHAKE.exe'
        $actual.action.echo | Should -Be 'PWSHAKE files: PWSHAKE.txt PWSHAKE.log PWSHAKE.key'
        $actual['$context'].template_key | Should -Be 'each'
      }
    }
  }
}
