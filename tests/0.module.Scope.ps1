[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
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
        Import-Module $PWD/pwshake/pwshake.psm1 -Force -DisableNameChecking -WarningAction SilentlyContinue
    }
    $specs = Get-ChildItem -Path $PSScriptRoot -Filter *$Group*.Specs.ps1 | Sort-Object | ForEach-Object {
        @{ path = $_.FullName; context = $context; verbosity = $verbosity }
    }
}

BeforeAll {
    InModuleScope pwshake { param($group, $context, $verbosity)
        # to use in internal specs
        ${pwshake-context}.invocations.Push(@{
                arguments = @{}
                config    = @{
                    attributes = @{
                        pwshake_verbosity = $verbosity
                        work_dir          = "$PWD"
                        pwshake_path      = "$PWD"
                        pwshake_log_path  = "TestDrive:\mock.log"
                    }
                }
                context   = Build-Context
            })
        # to speed up testing of recursions
        (Peek-Options).max_depth = 15
    } -Parameters @{ group = $Group; context = $Context; verbosity = $Verbosity }
}

Describe "<path>" -ForEach $specs {
    InModuleScope pwshake { param($path, $context, $verbosity)
        # dot source actual tests
        . $path -context $context -verbosity $verbosity
    } -Parameters $_
}

AfterAll {
    if (${pwshake-context}.invocations.Count) {
        ${pwshake-context}.invocations.Pop() | Out-Null
    }
}
