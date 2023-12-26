function New-Context {
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$parent,
    [Parameter(Position = 2, Mandatory = $true)]
    [hashtable]$arguments,
    [Parameter(Position = 3, Mandatory = $true)]
    [hashtable]$config
  )
  process {
    $context = @{}
    Get-ChildItem -Path (Split-Path $PSScriptRoot -Parent) -Include *.yaml, *.yml, *.json -Exclude pwshake.yaml -Recurse -File | ForEach-Object FullName | Sort-Object -Unique | ForEach-Object {
      $context = $context, ($_ | Build-FromYaml) | Merge-Object -Strategy Override
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
      Add-Type -IgnoreWarnings -TypeDefinition $_ -Language CSharp -WarningAction SilentlyContinue
    }

    $context.parent    = $parent
    $context.arguments = $arguments
    $context.config    = $config
    return $context
  }
}
