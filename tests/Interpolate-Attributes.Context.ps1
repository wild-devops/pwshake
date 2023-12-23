$ErrorActionPreference = "Stop"

Context "Interpolate-Attributes" {
    BeforeAll {
        $configPath = "$PWD/examples/4.complex/v1.0/complex_pwshake.yaml"
        (Peek-Invocation).config = $config = Load-Config -ConfigPath $configPath | Merge-Metadata -yamlPath $configPath
        # Write-Host -ForegroundColor DarkCyan ($config | cty)
    }

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

    It "Should substitute `$teamcity:build.number" {
        $env:TEAMCITY_BUILD_PROPERTIES_FILE = "$PWD/examples/4.complex/v1.0/build.properties"
        (Interpolate-Attributes @{
            c="{{`$teamcity:build.number}}"
        }).c | Should -Be "101"
    }

    It "Should substitute `$teamcity:build.counter" {
        $env:TEAMCITY_BUILD_PROPERTIES_FILE = "$PWD/examples/4.complex/v1.0/build.properties"
        (Interpolate-Attributes @{
            c="{{`$teamcity:build.counter}}"
        }).c | Should -Be "101"
    }

    It "Should substitute powershell: `$([System.Guid]::Empty)" {
        (Interpolate-Attributes @{
            c='{{$([System.Guid]::Empty)}}'
        }).c | Should -Be "00000000-0000-0000-0000-000000000000"
    }

    It "Should substitute complex powershell: `$('<When>' | ? {`$_} | % {`".`$_`"}) and a:'<And>' to '<Then>'" -TestCases @(
        @{When='';And='';Then=''}
        @{When='{{a}}';And='';Then=''}
        @{When='env';And='';Then='.env'}
        @{When='{{a}}';And='dev';Then='.dev'}
        @{When='{{b}}';And='dev';Then='.dev'}
    ) {param($When, $And, $Then)
        $subst = '{{$("' + $When + '" | ? {$_} | % {' + [Environment]::NewLine + '".$_"})}}'
        (Interpolate-Attributes @{
            attributes = @{
                a = $And
                b = '{{a}}'
                c = $subst
                d = '{{c}}'
            }
        }).attributes.d | Should -Be $Then
    }

    It "Should substitute crazy nested and composed build number: env_name:<env_name>, build_counter:<build_counter>" -TestCases @(
        @{env_name = ''; build_counter = ''; result = '7.5.0.dffb46c+'}
        @{env_name = 'caas'; build_counter = ''; result = '7.5.0.caas.dffb46c+'}
        @{env_name = 'caas'; build_counter = '42'; result = '7.5.0.caas.dffb46c+42'}
    ) {param($env_name, $build_counter, $result)
        $env:TEAMCITY_BUILD_COUNTER = $build_counter
        $env:BUILD_VCS_NUMBER_BSGITROOT = 'dffb46c3795ba2cde170fecba8942ee0f0512a36'

        (Interpolate-Attributes @{
            attributes = @{
                env_name = $env_name
                caas_version = '7.5.0'
                build_vcs_number = '{{$("$env:BUILD_VCS_NUMBER_BSGITROOT" | % {$_} | % {"$env:BUILD_VCS_NUMBER_BSGITROOT".Substring(0,7)})}}'
                env_part = '{{$("{{env_name}}" | ? {$_} | % {".$_"})}}'
                build_number = '{{caas_version}}{{env_part}}.{{build_vcs_number}}+{{$env:TEAMCITY_BUILD_COUNTER}}'
            }
        }).attributes.build_number | Should -Be $result
    }

    It "Should substitute string literals as strings" {
        $date_str = "$(Get-Date -f 'yyyy-MM-dd')"
        $path_str = '$("$env:PATH".Substring(0,4))' | Invoke-Expression
        @{
            attributes = @{
                a = '1,2,3'
                b = '{{a}}'
                c = '{{$(Get-Date -f "yyyy-MM-dd")}}'
                env_name = '{{c}}'
                override_to = '{{$("$env:PATH".Substring(0,4))}}'
                d = '{{env_name}}-windows.pwshake.{{override_to}}.{{b}}'
                win_fqdn = '{{d}}'
            }
        } | Interpolate-Attributes | New-Variable -Name actual
        $actual.attributes.a | Should -Be '1,2,3'
        $actual.attributes.b | Should -Be '1,2,3'
        $actual.attributes.c | Should -Be $date_str
        $actual.attributes.env_name | Should -Be $date_str
        $actual.attributes.override_to | Should -Be $path_str
        $actual.attributes.win_fqdn | Should -Be "$($date_str)-windows.pwshake.$($path_str).1,2,3"
    }

    It "Should throw on circular reference detected" {
        {
            Interpolate-Attributes @{
                attributes = @{a="{{b}}";b="{{c}}";c="{{a}}"};
            }
        } | Should -Throw "Circular reference detected for substitutions: {{a}} {{b}} {{c}}"
    }

    It "Should substitute special characters" {
        $chars = '`~!@#$qwest%^&*()_-=+\|][}{";?.,></№' + "'"

        Interpolate-Attributes @{
            attributes = @{a="{{b}}";b='{{$secured:{{c}}}}';c=$chars};
        } | Interpolate-Attributes | New-Variable -Name actual

        $actual.attributes.a | Should -Be $chars
        $actual.attributes.b | Should -Be $chars
        $actual.attributes.c | Should -Be $chars
    }

    It "Should substitute filters with multiple ':' separators and multiline input" {
        $expected = "https://some.url/?other`nvalue1:value2"

        Interpolate-Attributes @{
            attributes = @{a="{{b}}";b='{{$secured:{{c}}}}';c=$expected};
        } | New-Variable -Name actual

        $actual.attributes.a | Should -Be $expected
        $actual.attributes.b | Should -Be $expected
        $actual.attributes.c | Should -Be $expected
    }
}
