Context "Interpolate-Item" {

    It "Should throw on `$null" {
        { Interpolate-Item $null } | Should -Throw
    }

    It "Should return a Hashtable" {
        @'
        steps:
        - echo:
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | `
        Interpolate-Item | Should -BeOfType [Hashtable]
    }

    It "Should evaluate simple expression" {
        @'
        steps:
        - echo: '[[.]]'
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | ForEach-Object {
            'mock' | Interpolate-Item -step $_ | ForEach-Object echo | Should -Be 'mock'
        }
    }

    It "Should evaluate member expression on enumerator" {
        @'
        steps:
        - echo: '[[.Key]]'
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | ForEach-Object {
            (@{mock=$true}.GetEnumerator() | Select-Object -First 1) `
            | Interpolate-Item -step $_ | ForEach-Object echo | Should -Be 'mock'
        }
    }

    It "Should evaluate member expression on hashtable" {
        @'
        steps:
        - echo: '[[.Mock]]'
'@ | ConvertFrom-Yaml | ForEach-Object steps | Select-Object -First 1 | ForEach-Object {
            @{mock=$true} | Interpolate-Item -step $_ | ForEach-Object echo | Should -BeTrue
        }
    }

    It "Should evaluate on iterator with simple values" {
        @'
        input:
        - one
        - two
        - three
        steps:
        - echo: '[[.]]'
'@ | ConvertFrom-Yaml | ForEach-Object {
            $echo = $_ | ForEach-Object steps | Select-Object -First 1
            $_ | ForEach-Object input | ForEach-Object {
                $_ | Interpolate-Item -step $echo | ForEach-Object echo | Should -Be $_
            }
        }
    }

    It "Should evaluate on HashtableEnumerator entries" {
        @'
        input:
            one: two
            three: four
            five: six
        steps:
        - echo: '[[.Key]]:[[.Value]]'
'@ | ConvertFrom-Yaml | ForEach-Object {
            $echo = $_ | ForEach-Object steps | Select-Object -First 1
            $_.input.GetEnumerator() | ForEach-Object {
                $_ | Interpolate-Item -step $echo | ForEach-Object echo | Should -Be "$($_.Key)`:$($_.Value)"
            }
        }
    }

    It "Should evaluate on complex context" {
        @'
        context:
            Key: PWSHAKE
            Value: '[[.Key]]'
            Files:
            - '[[.Key]].txt'
            - '[[.Key]].log'
            - '[[.Key]].key'
            ListOfFiles: $[["$($_.Files)"]]
            AppService:
                Locations: '[[.Files]]'
                Executable: '[[.Key]]\[[.Value]].exe'
        tasks:
        - echo: 'Hello [[.Key]]!'
        - each:
            context: '[[.]]'
            items: $[[$_.Files]]
            action:
                echo: '[[.Key]] files: [[.ListOfFiles]]'
'@ | ConvertFrom-Yaml | ForEach-Object {
            $item = $_.context
            ($item | Interpolate-Item -step $_.tasks[0]).echo | Should -Be 'Hello PWSHAKE!'
             $item | Interpolate-Item -step $_.tasks[1] | ForEach-Object each | ForEach-Object {
                $_.context.Key | Should -Be 'PWSHAKE'
                $_.context.Value | Should -Be 'PWSHAKE'
                $_.context.Files | Should -Be @('PWSHAKE.txt', 'PWSHAKE.log', 'PWSHAKE.key')
                $_.context.ListOfFiles | Should -Be 'PWSHAKE.txt PWSHAKE.log PWSHAKE.key'
                $_.context.AppService.Locations | Should -Be @('PWSHAKE.txt', 'PWSHAKE.log', 'PWSHAKE.key')
                $_.context.AppService.Executable | Should -Be 'PWSHAKE\PWSHAKE.exe'
                $_.items | Should -Be @('PWSHAKE.txt', 'PWSHAKE.log', 'PWSHAKE.key')
                $_.action.echo | Should -Be 'PWSHAKE files: PWSHAKE.txt PWSHAKE.log PWSHAKE.key'
            }
        }
    }
}
