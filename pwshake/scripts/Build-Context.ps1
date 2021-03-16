function Build-Context {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [hashtable]$context = $null
  )
  process {
    $ErrorActionPreference = "Stop"

    if ($null -ne $context) { return $context } # just for tests

    $context = @{}
    Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '../context/*.yaml') | ForEach-Object {
      $context = Merge-Hashtables $context ($_.FullName | Build-FromYaml)
    }
    $context = $context | ForEach-Object 'pwshake-context'

    # to avoid change collection on enumeration exception using @() + ...
    foreach ($section in (@() + $context.Keys)) {
      $regex = [regex]'\$\[\[(?<eval>.*?)\]\]'
      if ($context.$($section) -is [hashtable]) {
        foreach ($key in (@() + $context.$($section).Keys)) {
          if ($context.$($section).$($key) -match $regex) {
            $context.$($section).$($key) = $matches.eval | Invoke-Expression
          }
        }
      }
      elseif (($context.$($section) -is [string]) -and ($context.$($section) -match $regex)) {
        $context.$($section) = $matches.eval | Invoke-Expression
      }
    }

    # to avoid premature evaluation in templates it runs after stages
    $templates = @{}
    foreach ($template in (Get-ChildItem -Path "$PSScriptRoot/../templates/*.yaml" -Recurse)) {
        $metadata = Build-FromYaml $template
        $templates = Merge-Hashtables $templates (Coalesce $metadata.templates, $metadata.actions, @{})
    }
    $context.templates = Merge-Hashtables $context.templates $templates

    $context.filters.GetEnumerator() | ForEach-Object {
      Invoke-Expression "filter script:$($_.Key) $($_.Value)"
    }

    $context.types | ForEach-Object type | ForEach-Object {
      Add-Type -TypeDefinition $_ -Language CSharp
    }

    return $context
  }
}
