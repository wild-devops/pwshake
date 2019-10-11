$ErrorActionPreference = "Stop"

Context "Arrange-Tasks" {
    $configPath = Get-RelativePath 'examples\module\pwshake.yaml'
    $config =  Load-Config $configPath | Merge-Metadata -yamlPath $configPath

    $config.tasks.role1 = @{name = 'role1';depends_on=@('errors')}
    $config.invoke_tasks = @('role1')

    It "Should return an Object[]" {
        (Arrange-Tasks $config) -is [Object[]] | Should -BeTrue
    }

    It "Should throw on circular reference in depends_on" {
        $config.tasks.role1.depends_on = @('role1')
        $config.tasks.role2 = @{
            name = 'role2'
            depends_on = @('role1')
        }
    
        { Arrange-Tasks $config } `
            | Should -Throw "Circular reference detected for dependant tasks in:"
    }
}
