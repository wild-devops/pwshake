$ErrorActionPreference = "Stop"

Context "Merge-MetaData" {
    BeforeAll {
        $metadataPath = Join-Path $PSScriptRoot\.. -ChildPath 'examples/4.complex/v1.0/metadata'
        $mock = @{}
    }

    It "Should return a Hashtable" {
        $mock, @{} | Merge-MetaData | Should -BeOfType System.Collections.Hashtable
    }

    It "Should merge a Hashtable" {
        $actual = (Merge-MetaData $mock @{a="b";c="d"}).attributes
        $actual.a | Should -Be "b"
        $actual.c | Should -Be "d"
        
    }

    It "Should read from a file '$metadataPath'" {
        (Merge-MetaData $mock $metadataPath).attributes.base_path | Should -Be "c:\qwe\rty\u\n#escaped"
    }

    It "Should read from a file '$metadataPath.yaml'" {
        (Merge-MetaData $mock "$metadataPath.yaml").attributes.base_path | Should -Be "c:\qwe\rty\u\n#escaped\yaml"
    }

    It "Should read from a file '$metadataPath.json'" {
        (Merge-MetaData $mock "$metadataPath.json").attributes.base_path | Should -Be "c:\qwe\rty\u\n#escaped\json"
    }

    It "Should read from multiline string" {
        $sut = @'
value=c:\qwe\rty#u\nc
class=[System]::Type
'@
        $actual = (Merge-MetaData $mock $sut).attributes
        $actual.value | Should -Be "c:\qwe\rty#u\nc"
        $actual.class | Should -Be "[System]::Type"
    }

    It "Should read from unescaped string" {
        $actual = (Merge-MetaData $mock "value=c:\qwe\rty#u\nc`nclass=[System]::Type").attributes
        $actual.value | Should -Be "c:\qwe\rty#u\nc"
        $actual.class | Should -Be "[System]::Type"
    }

    It "Should read from json string" {
        $actual = (Merge-MetaData $mock '{"value":"c:\\qwe\\rty#u\\nc","class":"[System]::Type"}').attributes
        $actual.value | Should -Be "c:\qwe\rty#u\nc"
        $actual.class | Should -Be "[System]::Type"
    }

    It "Should override invoke_tasks by given input" {
        $mock = @{
            invoke_tasks = @('1','2','3')
        }
        $actual = (Merge-MetaData $mock @{
            invoke_tasks = @('4','5','6')
        } -tasks @('mock','task'))

        $actual.invoke_tasks -is [Object[]] | Should -BeTrue 
        $actual.invoke_tasks.Count | Should -Be 2
        $actual.invoke_tasks[0] | Should -Be 'mock'
        $actual.invoke_tasks[1] | Should -Be 'task'
    }

    It "Should override invoke_tasks by single value" {
        $mock = @{
            invoke_tasks = @('1','2','3')
        }
        $actual = (Merge-MetaData $mock @{
            invoke_tasks = @('4','5','6')
        } -tasks 'mock')

        $actual.invoke_tasks -is [Object[]] | Should -BeTrue 
        $actual.invoke_tasks.Count | Should -Be 1
        $actual.invoke_tasks[0] | Should -Be 'mock'
    }
}
