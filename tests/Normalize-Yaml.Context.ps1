$ErrorActionPreference = "Stop"

Context "Normalize-Yaml" {
    $configPath = Get-RelativePath 'examples/corrupted.yaml'

    It "Should throw if ${configPath}1 file doesn't exist" {
        $configPath = "${configPath}1"

        {Normalize-Yaml $configPath} | Should -Throw "Cannot find path '$configPath' because it does not exist."
    }

    It "Should throw if ${configPath} file is corruped" {
        {Normalize-Yaml $configPath} | Should -Throw "File '$configPath' is corrupted:"
    }

    It "Should not throw if $(Get-RelativePath 'examples/metadata.yaml') file is fine" {
        {Normalize-Yaml (Get-RelativePath 'examples/metadata.yaml') | Out-Null} | Should -Not -Throw
    }
}
