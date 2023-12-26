filter f-log-err {
  if ((Peek-Verbosity) -lt [VerbosityLevel]::Error) { return }
  $Host.UI.WriteLine([ConsoleColor]'Red', [Console]::BackgroundColor, ($_ | f-error))
  if ((Peek-Verbosity) -eq [VerbosityLevel]::Debug) { 
    $_.ScriptStackTrace.Split([Environment]::NewLine) | Select-Object -First 5 | ForEach-Object {
      $Host.UI.WriteLine([ConsoleColor]::DarkYellow, [Console]::BackgroundColor, "TRACE: $_")
    }
  }
}
filter tee-wh-yaml {
  Write-Host "tee-wh-yaml:`n$($_ | f-cty)"; $_
}
filter f-error {
  @"
ERROR: $_
$($_.InvocationInfo.PositionMessage)
+ CategoryInfo : $($_.CategoryInfo.Category): ($($_.CategoryInfo.TargetName):$($_.CategoryInfo.TargetType)) [], $($_.CategoryInfo.Reason)
+ FullyQualifiedErrorId : $($_.FullyQualifiedErrorId)
"@
}
filter f-tmstmp {
  param($f = "$(Get-Date -format '[yyyy-MM-dd HH:mm:ss]') {0}", $skip = $false)
  $_ | Where-Object { !!$_ } | ForEach-Object { if (!$skip) { $f -f $_ } else { $_ } }
}
filter sb-append {
  param([Text.StringBuilder]$sb = (Peek-Data).json_sb)
  if (!!$sb) {
    $sb.AppendLine("$_") | Out-Null
  }
}
filter f-cnvp {
  Convert-Path $_ -ErrorAction 'Continue' 2>&1 | ForEach-Object {
    if ($_ -is [Management.Automation.ErrorRecord]) {
      $_.TargetObject
    }
    else {
      $_
    }
  }
}

filter f-template-key {
  param($add = @())
  Compare-Object (@() + $_.Keys) ($add + (Peek-Context).templates.Keys) `
    -PassThru -IncludeEqual -ExcludeDifferent # intersection
}

filter f-next-template-key {
  param($add = @(), $key)
  $clone = $_.Clone()
  $clone.Remove($key)
  $clone | f-template-key -a $add
}

filter f-is-list {
  ($_ -is [object[]]) -or ($_ -is [Collections.Generic.List[object]])
}

filter f-ps-creds {
  param([string]$user = 'token')
  [Management.Automation.PSCredential]::New($user, ("$_" | ConvertTo-SecureString -AsPlainText -Force))
}

filter f-wh-iex {
  Write-Host "$_"; &([scriptblock]::Create($_))
}

filter f-wh {
  param([ConsoleColor]$Color = 'Gray')
  $Host.UI.WriteLine($Color, [Console]::BackgroundColor, "$_")
}

filter f-wh-b {
  param([switch]$skip, [switch]$passthru)
  if (-not $skip) {
    $_ | f-wh -c 'DarkBlue'
  }
  if ($passthru) { $_ }
}

filter f-wh-c {
  param([switch]$skip, [switch]$passthru)
  if (-not $skip) {
    $_ | f-wh -c 'DarkCyan'
  }
  if ($passthru) { $_ }
}

filter f-wh-g {
  param([switch]$skip, [switch]$passthru)
  if (-not $skip) {
    $_ | f-wh -c 'DarkGreen'
  }
  if ($passthru) { $_ }
}

filter f-wh-m {
  param([switch]$skip, [switch]$passthru)
  if (-not $skip) {
    $_ | f-wh -c 'DarkMagenta'
  }
  if ($passthru) { $_ }
}

filter f-wh-r {
  param([switch]$skip, [switch]$passthru)
  if (-not $skip) {
    $_ | f-wh -c 'DarkRed'
  }
  if ($passthru) { $_ }
}

filter f-wh-y {
  param([switch]$skip, [switch]$passthru)
  if (-not $skip) {
    $_ | f-wh -c 'DarkYellow'
  }
  if ($passthru) { $_ }
}

filter f-null { param($f = '{0}') $_ | Where-Object { !!$_ } | ForEach-Object { $f -f "$_" } }
filter f-error {
  $msg = @"
ERROR: $_
$($_.InvocationInfo.PositionMessage)
+ CategoryInfo : $($_.CategoryInfo.Category): ($($_.CategoryInfo.TargetName):$($_.CategoryInfo.TargetType)) [], $($_.CategoryInfo.Reason)
+ FullyQualifiedErrorId : $($_.FullyQualifiedErrorId)
"@
  $Host.UI.WriteLine([ConsoleColor]::DarkYellow, [Console]::BackgroundColor, ($msg))
}

filter f-mask-secured {
  param($mask = '**********')
  $message = $_
  (Peek-Context).secured | ForEach-Object {
    if ([Regex]::new($([Regex]::Escape($_)), 'IgnoreCase').Match($message).Success) {
      $message = $message -replace "$([Regex]::Escape($_))", $mask
    }
  }
  $message
}

filter f-build-context {
  # usage: @{output='blah-blah'} | f-build-context
  "f-build-context:`n$('$_' | f-vars-cty)" | f-wh-m
  $ret = @{}
  if ($_ -isnot [hashtable]) {
    $ret['Value'] = $_
  }
  foreach ($key in $_.Keys) {
    $ret[$key] = $_.$($key)
  }
  return $ret
}
filter f-log-dbg {
  param([ConsoleColor]$Color = 'DarkCyan', [switch]$Force, [switch]$PassThru)
  # "f-log-dbg:In:`n$('$_' | f-vars-cty)" | f-wh-g
  if (("$(Peek-Verbosity)" -eq 'Debug') -or $force) {
    @{ # for further 'Log-Output' usage
      Value           = "DEBUG: $_";
      ForegroundColor = $Color
    } | ForEach-Object Value | f-wh -Color $Color
    # } | Log-Output | ForEach-Object Value | ForEach-Object {
    #   "f-log-dbg:Out:`n$('$_' | f-vars-cty)" | f-wh-c
    # }
    if ($PassThru) { $_ }
  }
}
filter f-cfy {
  $_ | psyml\ConvertFrom-Yaml -AsHashtable
}

filter f-cty {
  $_ | psyml\ConvertTo-Yaml 
}

filter f-cfj {
  $_ | ConvertFrom-Json -Depth 99 -AsHashtable 
}

filter f-ctj {
  $_ | ConvertTo-Json -Depth 99 
}

filter f-ctj-c {
  $_ | ConvertTo-Json -Depth 99 -Compress 
}

function f-tag-b { param($context, $next) Write-Host "`$next:b={$next}"; "<b>$(&$next $context)</b>" }
function f-tag-c {
  param($context, $next)
  Write-Host "`$next:c={$next}"
  "<c>$(&$next $context)</c>"
}
