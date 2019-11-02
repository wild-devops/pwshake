function Normalize-Context {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline= $true)]
        [hashtable]$context
    )
    process {
        $templates = @{}
        foreach ($template in (Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '../templates/*.yaml') -Recurse)) {
            $metadata = Normalize-Yaml $template
            $templates = Merge-Hashtables $templates $metadata.templates
        }

        return Merge-Hashtables $context @{
            templates = $templates;
        }
    }
}