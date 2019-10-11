$ErrorActionPreference = "Stop"

Context "Load-Config" {
    $configPath = Get-RelativePath 'examples/pwshake_config.yaml'
    $actual = Load-Config $configPath | Merge-Metadata -yamlPath $configPath

    It "Should read from $configPath" {
        $actual | Should -Not -BeNullOrEmpty
    }

    It "Should return a Hashtable" {
        $actual | Should -BeOfType [Hashtable]
    }

    It "Should populate service attributes" {
        $pwshakePath = (Split-Path $configPath -Parent)
        $workdir = (Split-Path $pwshakePath -Parent)
        $version = (Invoke-Expression (Get-Content "$(Join-Path $workdir -ChildPath 'pwshake\pwshake.psd1')" -Raw)).ModuleVersion

        $actual.attributes.work_dir | Should -Be "$workdir"
        $actual.attributes.pwshake_path | Should -Be "$pwshakePath"
        $actual.attributes.pwshake_version | Should -Be "$version"
        $actual.attributes.pwshake_module_path | Should -Be "$(Join-Path $workdir -ChildPath 'pwshake')"
        $actual.attributes.pwshake_log_path | Should -Be "$(($configPath).Replace('yaml','log'))"
    }

    It "Should throw if $configPath.mock file doesn't exist" {
        {Load-Config "$configPath.mock"} | Should -Throw "$configPath.mock does not exist."
    }
}
