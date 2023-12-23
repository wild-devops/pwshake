function Get-Matches {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$string,

    [Parameter(Position = 1, Mandatory = $true)]
    [regex]$regex,

    [Parameter(Position = 2, Mandatory = $true)]
    [string]$group
  )
  $regex.Matches($string) `
  | Select-Object -ExpandProperty Groups `
  | Where-Object Name -eq $group `
  | Select-Object -ExpandProperty Value
}

function Write-Line {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [string]$message = $null
  )    
  process {
    if (-not $message) {
      Write-Host ("=" * 80) -ForegroundColor "DarkMagenta"
    }
    else {
      $message += ' ' * ($message.Length % 2)
      $pad = "$('=' * [Math]::Abs(39 - ($message.Length / 2)))"
      Write-Host "$pad $message $pad" -ForegroundColor "DarkMagenta"
    }
  }
}

function Process-Context {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([object])]
  param (
    [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
    [object]$context,
    [Parameter(Position = 1)]
    [scriptblock]$next = { param([object]$context) $context }
  )
  process {
    return $context
  }
}

@{
  arguments = @{
    contextPath = '$contextPath'
    MetaData    = '$MetaData'
    Verbosity   = '$Verbosity'
    DryRun      = '[bool]$DryRun'
  }
} | Process-Context

$fs = @(
  { param($arg) "a" + $arg },
  { param($arg) "b" + $arg },
  { param($arg) "c" + $arg },
  { param($arg) "d" + $arg }
)
$composed = $fs | Merge-ScriptBlock
&$composed "e"

filter f-null { param($f = '{0}') $_ | Where-Object { !!$_ } | ForEach-Object { $f -f "$_" } }
filter script:f-error {
  $msg = @"
ERROR: $_
$($_.InvocationInfo.PositionMessage)
+ CategoryInfo : $($_.CategoryInfo.Category): ($($_.CategoryInfo.TargetName):$($_.CategoryInfo.TargetType)) [], $($_.CategoryInfo.Reason)
+ FullyQualifiedErrorId : $($_.FullyQualifiedErrorId)
"@
  $Host.UI.WriteLine([ConsoleColor]::DarkYellow, [Console]::BackgroundColor, ($msg))
}

function f-tag-b { param($context, $next) Write-Host "`$next:b={$next}"; "<b>$(&$next $context)</b>" }
. ./f-tag-c.ps1

function Merge-MiddleWare {
  [OutputType([scriptblock])]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateScript( { & { if ($_.Ast.Body) { $_.Ast.Body } else { $_.Ast } } | ForEach-Object { $_.ParamBlock.Parameters.Count -eq 2 } | Test-All } )]
    [scriptblock[]] $ScriptBlock
  )
  $reducer = { param($a, $b) { param([Parameter(Mandatory, ValueFromPipeline)]$context) # , $next={param($ctx) $ctx})
      # '' | Write-Line *>&1 | Write-Host -ForegroundColor DarkGreen
      # Write-Host "`$a: {$a}" -ForegroundColor DarkMagenta
      # Write-Host "`$b: {$b}" -ForegroundColor DarkCyan
      # Write-Host "`$next: {$next}" -ForegroundColor DarkYellow
      # &$b $context $a }.GetNewClosure() }
      , @($context) | &$b -next $a }.GetNewClosure() }
  # &$next (&$b $context $a) }.GetNewClosure() }
  # Write-Host "`$input`: $input" -ForegroundColor Blue; Write-Line
  $input | Reduce-Object $reducer
}

function Merge-PipeLine {
  [OutputType([scriptblock])]
  param(
    [Parameter(Mandatory)]
    [scriptblock[]] $ScriptBlock
  )
  $sb = $ScriptBlock.Clone()
  [array]::Reverse($sb)
  $sb | Merge-MiddleWare # | % {Write-Host "$_" -ForegroundColor Yellow; $_}
}

# $pipeline = Merge-PipeLine @(
#   { param($context, $next) Write-Host "`$next:a={$next}"; throw "<a>$(&$next $context)</a>" }
#   ,${function:f-tag-b}
#   ,${function:f-tag-c}
#   ,[scriptblock]::Create('param($context, $next) Write-Host "`$next:d={$next}"; "<d>$(&$next $context)</d>"')
# )

$f_list = @('Start-Pipeline', 'Process-Step')

$pwshake = Merge-PipeLine @(
  (Get-Item function:$($f_list[0])).ScriptBlock
  , { param([Parameter(Mandatory, ValueFromPipeline)]$context, $next)
    Write-Line "Load resources"
    Write-Host "`$context:`n$($context.resources | cty)" -ForegroundColor DarkGreen
    $context.resources | ForEach-Object pwsh | ForEach-Object {
      &([scriptblock]::Create($_)) *>&1
    }
    $context | &$next
  }
  , { param([Parameter(Mandatory, ValueFromPipeline)]$context, $next)
    Write-Line "Interpolate attributes"
    Write-Host "`$context:`n$($context | cty)" -ForegroundColor DarkGreen
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
      $context = $json | f-cfj
      $json = ConvertTo-Json $context -Depth 99 -Compress
    } while ($regex.Match($json).Success)

    $json | f-cfj | &$next
  }
  , { param([Parameter(Mandatory, ValueFromPipeline)]$config, $next)
    Write-Line "Process config"
    Write-Host "Config:`n$($config | cty)"
    foreach ($task_key in $config.invoke_tasks) {
      Write-Line "Task: $task_key"
      # Write-Line (''.PadRight(38 - "$task_key".Length,' ') + "$task_key".PadRight(38,' '))
      # Write-Line ("")
      # Write-Host "`$task_key: $task_key" -ForegroundColor DarkYellow
      , @($config.tasks.$($task_key)) | &$next
    }
  }
  , { param([Parameter(Mandatory, ValueFromPipeline)]$task, $next)
    Write-Host "Task:`n$($task | cty)"
    foreach ($step in $task) {
      $step | &$next
    }
  }
  , { param([Parameter(Mandatory, ValueFromPipeline)]$step, $next)
    process {
      '' | Write-Line 6>&1 | Write-Host -ForegroundColor Yellow
      Write-Host "Step:`n$($_ | cty)"
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
  }
  , (Get-Item function:$($f_list[1])).ScriptBlock
)

'.\examples\1.hello\v1.5\my_pwshake.yaml' | &$pwshake
