$ErrorActionPreference = "Stop"

. ./f-tag-c.ps1

Get-ChildItem $PSScriptRoot\pwshake\functional\* -File -Include *.ps1 | Sort-Object | ForEach-Object {
  . $_.FullName
}

$fs = @(
  { param($arg) "a" + $arg },
  { param($arg) "b" + $arg },
  { param($arg) "c" + $arg },
  { param($arg) "d" + $arg }
)
$composed = $fs | Merge-ScriptBlock
&$composed "e"

$f_list = @('Start-Pipeline', 'Process-Step')

$pipeline = Merge-PipeLine @(
  (Get-Item function:$($f_list[0])).ScriptBlock,
  { param([Parameter(Mandatory, ValueFromPipeline)]$context, $next)
    Write-Line "Load resources"
    Write-Host "`$context:`n$($context.resources | f-cfy)" -ForegroundColor DarkGreen
    $context.resources | ForEach-Object pwsh | ForEach-Object {
      &([scriptblock]::Create($_)) *>&1
    }
    $context | &$next
  },
  { param([Parameter(Mandatory, ValueFromPipeline)]$context, $next)
    Write-Line "Interpolate attributes"
    Write-Host "`$context:`n$($context | f-cfy)" -ForegroundColor DarkGreen
    $json = $context | ConvertTo-Json -Depth 99 -Compress
    $regex = [regex]'{{(?<subst>(?:(?!{{).)+?)}}'
    do {
      foreach ($substitute in (Get-Matches $json $regex 'subst')) {
        if ($substitute -match '(?ms)^\$\((?<eval>.*)\)$') {
          $value = "`"$($matches.eval)`"" | ConvertFrom-Json | Invoke-Expression
        }
        else {
          $value = Invoke-Expression "`$context.attributes.$substitute" -ErrorAction Stop
          if ($regex.Match($value).Success) {
            continue;
          }
        }
        $value = $value | f-null | ForEach-Object { (ConvertTo-Json $_ -Compress -Depth 99).Trim('"') }
        $json = $json.Replace("{{$substitute}}", "$value")
      }
      $context = $json | ConvertFrom-Json
      $json = ConvertTo-Json $context -Depth 99 -Compress
    } while ($regex.Match($json).Success)

    $json | ConvertFrom-Json | &$next
  },
  { param([Parameter(Mandatory, ValueFromPipeline)]$config, $next)
    Write-Line "Process config"
    Write-Host "`$context:`n$($config | f-cfy)" -ForegroundColor DarkGreen
    foreach ($task_key in $config.invoke_tasks) {
      Write-Line "Task: $task_key"
      # Write-Line (''.PadRight(38 - "$task_key".Length,' ') + "$task_key".PadRight(38,' '))
      # Write-Line ('')
      # Write-Host "`$task_key: $task_key" -ForegroundColor DarkYellow
      , @($config.tasks.$($task_key)) | &$next
    }
  },
  { param([Parameter(Mandatory, ValueFromPipeline)]$task, $next)
    Write-Host "`$context:`n$($task | f-cfy)" -ForegroundColor DarkGreen
    foreach ($step in $task) {
      $step | &$next
    }
  },
  { param([Parameter(Mandatory, ValueFromPipeline)]$step, $next)
    process {
      '' | Write-Line 6>&1 | Write-Host -ForegroundColor Yellow
      Write-Host "`$context:`n$($step | f-cfy)" -ForegroundColor DarkGreen
      try {
        $step | &$next
      }
      catch {
        if ($step.on_error -eq 'continue') {
          $_ | f-error
        }
        else {
          throw $_
        }
      }
    }
  },
  (Get-Item function:$($f_list[1])).ScriptBlock
)

$arguments = @{
  ConfigPath = '.\examples\1.hello\v1.5\my_pwshake.yaml'
  Tasks      = @()
  MetaData   = @{}
  Verbosity  = 'Debug'
  DryRun     = $false
}

$script:PSScriptRoot_ = '/workdir/pwshake'
Invoke-actor @arguments -ErrorAction Continue
@(
  'gci variable:actor*'
) | f-wh-iex
