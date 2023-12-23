$ErrorActionPreference = "Stop"

Context "Arrange-Tasks" {
    BeforeAll {
        $configPath = "$PWD/examples/4.complex/v1.0/module/pwshake.yaml"
        (Peek-Invocation).config = $config = Load-Config -ConfigPath $configPath | Merge-Metadata -yamlPath $configPath

        $config.tasks.role1 = @{name = 'role1'; depends_on = @('errors') }
        $config.invoke_tasks = @('role1')
    }

    It "Should return an Object[]" {
        ($config.invoke_tasks | Arrange-Tasks) -is [object[]] | Should -BeTrue
    }

    It "Should throw on circular reference in depends_on" {
        $config.tasks.role1.depends_on = @('role1')
        $config.tasks.role2 = @{
            name       = 'role2'
            depends_on = @('role1')
        }

        {
            $config.invoke_tasks | Arrange-Tasks
        } | Should -Throw "Circular reference detected for dependant tasks in: role1"
    }
}
