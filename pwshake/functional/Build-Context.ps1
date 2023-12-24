function Build-Context {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param ()
  Process {
    $context = @{}
    $parent = (Split-Path $PSScriptRoot -Parent | Get-Item).FullName
    Get-ChildItem -Path $parent\context\*, $parent\templates\* -Include *.yaml, *.yml -File | ForEach-Object FullName | Sort-Object | ForEach-Object {
      $context = $context, ($_ | Build-FromYaml) | Merge-Object -Strategy Override
    }
    $context = $context | ForEach-Object 'pwshake-context'

    $context.types | ForEach-Object type | ForEach-Object {
      Add-Type -IgnoreWarnings -TypeDefinition ($_) -Language CSharp -WarningAction SilentlyContinue
    }

    $context.filters.GetEnumerator() | ForEach-Object {
      Invoke-Expression "filter script:$($_.Key) $($_.Value)"
    }

    $context.functions.GetEnumerator() | ForEach-Object {
      Invoke-Expression "function script:$($_.Key) $($_.Value)"
    }

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

    return $context
  }
}
