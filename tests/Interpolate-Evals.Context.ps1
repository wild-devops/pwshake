Context "Interpolate-Evals" {

    It "Should throw on `$null" {
        { Interpolate-Evals $null } | Should -Throw
    }

    It "Should return a Hashtable" {
        @'
steps:
- echo:
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | `
            Interpolate-Evals | Should -BeOfType [Hashtable]
    }

    It "Should evaluate simple expression" {
        @'
steps:
- echo: $[[$true]]
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | `
            Interpolate-Evals | ForEach-Object echo | Should -Be 'True'
    }

    It "Should evaluate simple quoted string expression" {
        @'
steps:
- echo: $[["$($true)"]]
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | `
            Interpolate-Evals | ForEach-Object echo | Should -Be 'True'
    }

    It "Should evaluate complex expression" {
        @'
steps:
- version: 1.2.3.4
  echo: $[[$step.version.Replace('.','_')]]
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | `
            Interpolate-Evals | ForEach-Object echo | Should -Be '1_2_3_4'
    }

    It "Should evaluate complex quoted string expression" {
        @'
steps:
- version: 1.2.3.4
  echo: $[["$($step.version.Replace('.','_'))"]]
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | `
            Interpolate-Evals | ForEach-Object echo | Should -Be '1_2_3_4'
    }

    It "Should evaluate dependent expression" {
        @'
steps:
- semver:
  - '1'
  - '2'
  - '3'
  - '4'
  echo: $[[$step.semver -join '.']]
  version: $[echo["$($step.echo.Replace('.','_'))"]]
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | `
            Interpolate-Evals | ForEach-Object {
            $_.echo | Should -Be '1.2.3.4'
            $_.version | Should -Be '1_2_3_4'
        }
    }

    It "Should evaluate expression with alternate syntax" {
        @'
steps:
- semver:
  - 1
  - 2
  - 3
  - 4
  version: '{{$step.semver -join "."}}'
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | `
            Interpolate-Evals -regex '{{(?<eval>.*?)}}' | ForEach-Object {
            $_.version | Should -Be '1.2.3.4'
            $_ | Should -BeOfType [Hashtable]
            $_.Keys.Count | Should -Be 2
            $_.Keys | Should -Contain 'version'
            $_.Keys | Should -Contain 'semver'
            $_.Keys | Should -Not -Contain '$context'
        }
    }

    It "Should preserve context and evaluate complex payload" {
        # Arrange
        $mock = (@'
steps:
- $context:
    json_sb:
  semver:
  - 1
  - 2
  - 3
  - 4
  echo: $[[$step.semver]]
  version: $[echo[$step.echo -join '.']]
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1)
        $mock['$context'].json_sb = New-Object 'Text.StringBuilder'
        $mock['$context'].json_sb.Append('mock')

        # Act
        Interpolate-Evals $mock | ForEach-Object {
            # Assert
            $_ | Should -BeOfType [Hashtable]
            $_.Keys.Count | Should -Be 4
            $_.Keys | Should -Contain 'echo'
            $_.Keys | Should -Contain 'semver'
            $_.Keys | Should -Contain '$context'
            $_.Keys | Should -Contain 'version'
            $_.Keys | Should -Not -Contain 'json_sb'
            $_['$context'].Keys.Count | Should -Be 1
            $_['$context'].Keys | Should -Contain 'json_sb'
            $_['$context'].json_sb.ToString() | Should -Be 'mock'
            "$($_.echo)" | Should -Be "$($_.semver)"
            $_.version | Should -Be '1.2.3.4'

        }
    }

    It "Should evaluate complex payload via template key" {
        @'
steps:
- $context:
    template_key: mock
  semver:
  - 1
  - 2
  - 3
  - 4
  echo: $[[$mock.semver]]
  version: $[echo[$mock.echo -join '.']]
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | `
            Interpolate-Evals | ForEach-Object {
            # Assert
            $_ | Should -BeOfType [Hashtable]
            $_.Keys.Count | Should -Be 4
            $_.Keys | Should -Contain 'echo'
            $_.Keys | Should -Contain 'semver'
            $_.Keys | Should -Contain '$context'
            $_.Keys | Should -Contain 'version'
            $_.Keys | Should -Not -Contain 'template_key'
            $_['$context'].Keys.Count | Should -Be 1
            $_['$context'].Keys | Should -Contain 'template_key'
            $_['$context'].template_key | Should -Be 'mock'
            "$($_.echo)" | Should -Be "$($_.semver)"
            $_.version | Should -Be '1.2.3.4'

        }
    }
}
