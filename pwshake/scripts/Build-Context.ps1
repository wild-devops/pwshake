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
    Get-ChildItem -Path (Split-Path $PSScriptRoot -Parent) -Include *.yaml,*.yml,*json -Recurse | ForEach-Object {
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

    $context.filters.GetEnumerator() | ForEach-Object {
      Invoke-Expression "filter script:$($_.Key) $($_.Value)"
    }

    $context.types | ForEach-Object type | ForEach-Object {
      Add-Type -IgnoreWarnings -TypeDefinition $_ -Language CSharp
    }

    return $context
  }
}
