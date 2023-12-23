$ErrorActionPreference = "Stop"

Context "Override-Attributes" {
    BeforeAll {
        $configPath = "$PWD/examples/4.complex/v1.0/complex_pwshake.yaml"
        (Peek-Invocation).config = $config = Load-Config -ConfigPath $configPath | Merge-Metadata -yamlPath $configPath
    }

    It "Should return a Hashtable" {
        Override-Attributes $config | Should -BeOfType [Hashtable]
    }

    It "Should thow on unknown type of item" {
        {
            Merge-Hashtables $config @{
                attributes_overrides = @((New-Object Collections.Stack), 'mock');
            } | Override-Attributes
        } | Should -Throw "Unknown type of 'attributes_overrides:' item: 'System.Collections.Stack'."
    }

    It "Should throw on more than one item" {
        {
            Merge-Hashtables $config @{
                attributes_overrides = @(@{one='two';three='four'});
            } | Override-Attributes
        } | Should -Throw "Item of 'attributes_overrides:' can't contain 2 keys."
    }

    It "Should throw on unresolved relative path" {
        {
            Merge-Hashtables $config @{
                attributes_overrides = @(@{mock='mock'});
            } | Override-Attributes
        } | Should -Throw "Unknown path: mock"
    }

    It "Should throw on unresolved implicit path" {
        {
            Merge-Hashtables $config @{
                attributes_overrides = @('mock');
            } | Override-Attributes
        } | Should -Throw "Cannot find path '$(Join-Path ($configPath | f-dir-name) attributes_overrides/mock.yaml)' because it does not exist."
    }

    It "Should override attributes from relative spesified file" {
        (Merge-Hashtables $config @{
            attributes = @{override_to='mock'};
            attributes_overrides = @(@{mock='attributes.json'});
        } | Override-Attributes).attributes.sql_server | Should -Be 'undefined'
    }

    It "Should override attributes from explicit spesified file" {
        $path = "$(Join-Path ($configPath | f-dir-name) attributes_overrides/local.yaml)"
        (Merge-Hashtables $config @{
            attributes = @{override_to='mock'};
            attributes_overrides = @(@{mock=$path});
        } | Override-Attributes).attributes.sql_server | Should -Be 'localhost'
    }
}
