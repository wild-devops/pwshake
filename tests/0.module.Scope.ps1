[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('internal', 'examples', 'public', 'asserts', 'publish')]
    [string]$Group = '',

    [Parameter(Mandatory = $false)]
    [string]$Context = '',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Error', 'Warning', 'Minimal', 'Information', 'Verbose', 'Debug', 'Normal', 'Default')]
    [string]$Verbosity = 'Error'
)

BeforeDiscovery {
    if (-not ${pwshake-context}.invocations.Count) {
        Get-Module pwshake -ListAvailable | Remove-Module -Force | Out-Null
        Import-Module $PSScriptRoot\..\pwshake\pwshake.psm1 -Force -DisableNameChecking -WarningAction SilentlyContinue -Verbose
    }

    $specs = Get-ChildItem -Path $PSScriptRoot -Filter *$Group*.Specs.ps1 | Sort-Object | ForEach-Object {
        @{ path = $_.FullName; cntx = $Context }
    }
    ${pwshake-context}.invocations.Push(@{
        arguments = @{}
        options   = @{
            max_depth = 15
        }
        config    = @{
            attributes = @{
                pwshake_verbosity = $Verbosity
                work_dir          = "$PWD"
                pwshake_path      = "$PWD"
                pwshake_log_path  = "TestDrive:\mock.log"
            }
        }
    })
}

Describe "<path>" -ForEach $specs {
    InModuleScope pwshake { param([string]$path, [string]$cntx)
        # dot source actual tests
        . $path -Context $cntx
    } -Parameters $_
}

AfterAll {
    if (${pwshake-context}.invocations.Count) {
        ${pwshake-context}.invocations.Pop() | Out-Null
    }
}
