$ErrorActionPreference = "Stop"

Context "Interpolate-Attributes" {
    $configPath = Get-RelativePath 'examples/pwshake_config.yaml'
    $config = Load-Config $configPath | Merge-Metadata -yamlPath $configPath

    It "Should return a Hashtable" {
        Interpolate-Attributes $config | Should -BeOfType [Hashtable]
    }

    It "Should substitute simple key" {
        (Interpolate-Attributes @{
            attributes = @{a="b"};
            c = "{{a}}"
        }).c | Should -Be "b"
    }

    It "Should substitute nested key" {
        (Interpolate-Attributes @{
            attributes = @{a=@{b="c"}};
            d="{{a.b}}"
        }).d | Should -Be "c"
    }

    It "Should substitute chain of keys" {
        (Interpolate-Attributes @{
            attributes = @{a="{{b}}";b="{{c}}";c="d"}
        }).attributes.a | Should -Be "d"
    }

    It "Should substitute `$env:PWSHAKE_VARIABLE" {
        $env:PWSHAKE_VARIABLE = "`$env:PWSHAKE_VARIABLE_VALUE"
        (Interpolate-Attributes @{
            c="{{`$env:PWSHAKE_VARIABLE}}"
        }).c | Should -Be "`$env:PWSHAKE_VARIABLE_VALUE"
    }

    It "Should substitute powershell: `$([System.Guid]::Empty)" {
        (Interpolate-Attributes @{
            c='{{$([System.Guid]::Empty)}}'
        }).c | Should -Be "00000000-0000-0000-0000-000000000000"
    }

    It "Should throw on circular reference detected" {
        {
            Interpolate-Attributes @{
                attributes = @{a="{{b}}";b="{{c}}";c="{{a}}"};
            }
        } | Should -Throw "Circular reference detected for substitutions: {{a}} {{b}} {{c}}"
    }
}
