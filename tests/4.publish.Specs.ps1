[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Context = '',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Error', 'Warning', 'Minimal', 'Information', 'Verbose', 'Debug', 'Normal', 'Default')]
    [string]$Verbosity = 'Error'
)

Context "PWSHAKE publication" {

    BeforeEach {
        Mock Write-Host {}
    }

    It "Should invoke Publish-Module" {
        # Arrange
        $env:PSGALLERY_API_TOKEN = "123"
        Mock Publish-Module {}

        # Act
        & "$PWD\tools\publish.ps1"
        # Assert
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ParameterFilter { $Object -eq "Publishing the PWSHAKE module`n" }
        Assert-MockCalled Publish-Module -Exactly 1 -Scope It -ParameterFilter { 
            ($Repository -eq 'PSGallery') -and `
            ($NuGetApiKey -eq '123')
        }
    }

    It "Should twrow if `$env:PSGALLERY_API_TOKEN is empty" {
        $env:PSGALLERY_API_TOKEN = ""
        {
            & "$PWD\tools\publish.ps1"
        } | Should -Throw '$attributes.api_token is empty'
    }
}
