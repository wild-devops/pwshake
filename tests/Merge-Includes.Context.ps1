$ErrorActionPreference = "Stop"

Context "Merge-Includes" {
    $configPath = Get-RelativePath 'examples/4.complex/v1.0/includes/module1.yaml'
    $config =  Load-Config $configPath | Merge-Metadata -yamlPath $configPath

    $config.includes = @(
        "module2.json"
    )

    $actual = $config | Merge-Includes -yamlPath $configPath

    It "Should return a Hashtable" {
        $actual | Should -BeOfType [Hashtable]
    }

    It "Should contain invoke_tasks: populated with ordered items and without duplication" {
        $actual.invoke_tasks.Count | Should -Be 6
        $actual.invoke_tasks[0] | Should -Be "role1"
        $actual.invoke_tasks[1] | Should -Be "role2"
        $actual.invoke_tasks[2] | Should -Be "run_list3"
        $actual.invoke_tasks[3] | Should -Be "run_list4"
        $actual.invoke_tasks[4] | Should -Be "role5"
        $actual.invoke_tasks[5] | Should -Be "role6"
    }

    It "Should not contain duplicated attributes_overrides: items" {
        $actual.attributes_overrides.Count | Should -Be 3
        $actual.attributes_overrides | Should -Contain "test"
        $actual.attributes_overrides | Should -Contain "stage"
        $actual.attributes_overrides | Should -Contain "prod"
    }

    It "Should contain adjusted scripts_directories: items" {
        $actual.scripts_directories.Count | Should -Be 3
        $actual.scripts_directories | Should -Contain "."
        $actual.scripts_directories | Should -Contain "module1"
        $actual.scripts_directories | Should -Contain "module2"
    }

    It "Should contain overriden tasks: elements" {
        $actual.tasks.Keys.Count | Should -Be 3
        $actual.tasks.Keys | Should -Contain "role1"
        $actual.tasks.Keys | Should -Contain "role2"
        $actual.tasks.Keys | Should -Contain "role3"
        $actual.tasks.role1 | Should -Be "role1"
        $actual.tasks.role2 | Should -Be "role2"
        $actual.tasks.role3 | Should -Be "role3"
    }

    It "Should throw on circular reference in includes" {
        $config.includes = @(
            "module3.json"
        )
    
        { $config | Merge-Includes -yamlPath $configPath } `
            | Should -Throw "Circular reference detected for includes in:"
    }
}
