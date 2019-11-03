$ErrorActionPreference = "Stop"

Context "Normalize-Yaml" {
    $configPath = Get-RelativePath 'examples/6.errors/v1.3/corrupted.yaml'

    It "Should throw if ${configPath}1 file doesn't exist" {
        $configPath = "${configPath}1"

        {Normalize-Yaml $configPath} | Should -Throw "Cannot find path '$configPath' because it does not exist."
    }

    It "Should throw if ${configPath} file is corruped" {
        {Normalize-Yaml $configPath} | Should -Throw "File '$configPath' is corrupted:"
    }

    It "Should not throw if $(Get-RelativePath 'examples/4.complex/v1.0/metadata.yaml') file is fine" {
        {Normalize-Yaml (Get-RelativePath 'examples/4.complex/v1.0/metadata.yaml') | Out-Null} | Should -Not -Throw
    }
}
