function Load-Config {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$YamlPath
    )
    process {
        $config = $YamlPath | Normalize-Yaml | Normalize-Config

        $config.attributes.pwshake_path = "$(Split-Path $YamlPath -Resolve)"
        $config.attributes.pwshake_log_path = (Join-Path -Path $config.attributes.pwshake_path -ChildPath "$((Resolve-Path $YamlPath | Get-Item).BaseName).log").ToString()
        $config.attributes.pwshake_module_path = "$(Split-Path $PSScriptRoot -Parent)"
        $config.attributes.pwshake_version = (Invoke-Expression (Get-Content $PSScriptRoot\..\pwshake.psd1 -Raw)).ModuleVersion
        $config.attributes.work_dir = "$(Get-Location)"
        if (-not $config.attributes.pwshake_verbosity) {
            $config.attributes.pwshake_verbosity = ${pwshake-context}.verbosity
        }
        if (-not $config.scripts_directories) {
            $config.scripts_directories = @('.')
        }
        if (($config.scripts_directories.Count) -and (-not $config.scripts_directories.Contains('.'))) {
            $config.scripts_directories += '.'
        }
        if (Test-Path $config.attributes.pwshake_log_path) {
            Remove-Item -Path $config.attributes.pwshake_log_path -Force
        }

        return $config
    }
}