function Process-Context {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([object])]
  param (
    [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
    [object]$context,
    [Parameter(Position = 1)]
    [scriptblock]$next = {param([object]$context) $context}
  )
  process {
    return $context
  }
}

@{
  arguments = @{
    contextPath  = '$contextPath'
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

filter f-null { param($f = '{0}') $_ | Where-Object { !!$_ } | ForEach-Object { $f -f "$_"} }
filter script:f-error {
  $msg = @"
ERROR: $_
$($_.InvocationInfo.PositionMessage)
+ CategoryInfo : $($_.CategoryInfo.Category): ($($_.CategoryInfo.TargetName):$($_.CategoryInfo.TargetType)) [], $($_.CategoryInfo.Reason)
+ FullyQualifiedErrorId : $($_.FullyQualifiedErrorId)
"@
$Host.UI.WriteLine([ConsoleColor]::DarkYellow,[Console]::BackgroundColor,($msg))
}

function f-tag-b { param($context, $next) Write-Host "`$next:b={$next}"; "<b>$(&$next $context)</b>" }
. ./f-tag-c.ps1

function Merge-MiddleWare {
  [OutputType([scriptblock])]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateScript( { $_ | ForEach-Object { $_.Ast.ParamBlock.Parameters.Count -eq 2 } | Test-All } )]
    [scriptblock[]] $ScriptBlock
  )
  $reducer = { param($a, $b) { param($context) # , $next={param($ctx) $ctx})
    # '' | Write-Line *>&1 | Write-Host -ForegroundColor DarkGreen
    # Write-Host "`$a: {$a}" -ForegroundColor DarkMagenta
    # Write-Host "`$b: {$b}" -ForegroundColor DarkCyan
    # Write-Host "`$next: {$next}" -ForegroundColor DarkYellow
    &$b $context $a }.GetNewClosure() }
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

$pwshake = Merge-PipeLine @(
  { param($context, $next)
    Write-Line "Start pipeline"
    Write-Host "`$context:`n$($context | cty)" -ForegroundColor DarkGreen
    try {
      &$next (Get-Content -Path $context -Raw | cfy)
    }
    catch {
      $_.ScriptStackTrace.Split([Environment]::NewLine) | f-null | Select-Object -First 5 | ForEach-Object {
        "TRACE: $_" | ForEach-Object {
          $Host.UI.WriteLine([ConsoleColor]::Yellow,[Console]::BackgroundColor, $_)
        }
      }
      throw $_  
    }
  }
  ,{ param($context, $next)
      Write-Line "Interpolate attributes"
      Write-Host "`$context:`n$($context | cty)" -ForegroundColor DarkGreen
          $json = $context | ConvertTo-Json -Depth 99 -Compress
      $regex = [regex]'{{(?<subst>(?:(?!{{).)+?)}}'
      do {
        foreach ($substitute in (Get-Matches $json $regex 'subst')) {
          if ($substitute -match '(?ms)^\$\((?<eval>.*)\)$') {
            $value = "`"$($matches.eval)`"" | ConvertFrom-Json | Invoke-Expression
          } else {
            $value = Invoke-Expression "`$context.attributes.$substitute" -ErrorAction Stop
            if ($regex.Match($value).Success) {
                continue;
            }
          }
          $value = $value | f-null | ForEach-Object {(ConvertTo-Json $_ -Compress -Depth 99).Trim('"')}
          $json = $json.Replace("{{$substitute}}", "$value")
        }
        $context = ConvertFrom-Yaml $json
        $json = ConvertTo-Json $context -Depth 99 -Compress
      } while ($regex.Match($json).Success)

      &$next ($json | ConvertFrom-Yaml)
  }
  ,{ param($context, $next)
    Write-Line "Process config"
    Write-Host "Config:`n$($context | cty)"
    foreach ($task_key in $context.invoke_tasks) {
      Write-Line "Task: $task_key"
      # Write-Line (''.PadRight(38 - "$task_key".Length,' ') + "$task_key".PadRight(38,' '))
      # Write-Line ("")
      # Write-Host "`$task_key: $task_key" -ForegroundColor DarkYellow
      &$next ($context.tasks.$($task_key))
    }
  }
  ,{ param($context, $next)
    Write-Host "Task:`n$($context | cty)"
    foreach ($step in $context) {
      &$next $step
    }
  }
  ,{ param($context, $next)
    '' | Write-Line 6>&1 | Write-Host -ForegroundColor Yellow
    Write-Host "Step:`n$($context | cty)"
    switch ($context.Keys) {
      {$_ -eq 'on_error'} {  }
      {$_ -eq 'echo'} {
        Write-Host $context.$($_) -ForegroundColor Green
      }
      {$_ -eq 'pwsh'} {
        try {
          &([scriptblock]::Create($context.$($_))) *>&1
        }
        catch {
          if ($context.on_error -eq 'continue') {
            $_ | f-error
          } else {
            throw $_
          }
        }
      }
      default {
        if ($context.on_error -ne 'continue') {
          throw "Unknown step type: '$_'." }
        }
    }
  }
)

&$pwshake '.\examples\1.hello\v1.5\my_pwshake.yaml'
