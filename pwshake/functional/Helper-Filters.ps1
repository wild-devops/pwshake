function Peek-Invocation {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param()
  if (${pwshake-context}.invocations.Count -eq 0) {
    return $null
  }
  return ${pwshake-context}.invocations.Peek()
}

function Peek-Context {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param()
  return (Peek-Invocation).context
}

function Peek-Config {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param()
  return (Peek-Invocation).config
}

function Peek-Data {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param()
  return (Peek-Context).data
}

function Peek-Options {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param()
  return (Peek-Context).options
}

function Peek-Pipelines {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param()
  return (Peek-Context).pipelines
}

function Peek-Verbosity {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param()
  return [PWSHAKE.VerbosityLevel](Coalesce (Peek-Config).attributes.pwshake_verbosity, 'Default')
}
function Peek-LogPath {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param()
  return (Coalesce (Peek-Config).attributes.pwshake_log_path, ("$PWD/pwshake.log" | f-cnvp))
}

filter f-log-err {
  # if ((Peek-Verbosity) -lt [PWSHAKE.VerbosityLevel]::Error) { return }
  $Host.UI.WriteLine([ConsoleColor]'Red', [Console]::BackgroundColor, ($_ | f-error))
  # if ((Peek-Verbosity) -eq [PWSHAKE.VerbosityLevel]::Debug) { 
  $_.ScriptStackTrace.Split([Environment]::NewLine) | Select-Object -First 5 | ForEach-Object {
    $Host.UI.WriteLine([ConsoleColor]::DarkYellow, [Console]::BackgroundColor, "TRACE: $_")
  }
  # }
}
filter script:tee-wh-yaml {
  Write-Host "tee-wh-yaml:`n$(ConvertTo-Yaml $_)"; $_
}
filter script:f-error {
  @"
ERROR: $_
$($_.InvocationInfo.PositionMessage)
+ CategoryInfo : $($_.CategoryInfo.Category): ($($_.CategoryInfo.TargetName):$($_.CategoryInfo.TargetType)) [], $($_.CategoryInfo.Reason)
+ FullyQualifiedErrorId : $($_.FullyQualifiedErrorId)
"@
}
filter script:f-tmstmp {
  param($f = "$(Get-Date -format '[yyyy-MM-dd HH:mm:ss]') {0}", $skip = $false)
  $_ | Where-Object { !!$_ } | ForEach-Object { if (!$skip) { $f -f $_ } else { $_ } }
}
filter script:sb-append {
  param([Text.StringBuilder]$sb = (Peek-Data).json_sb)
  if (!!$sb) {
    $sb.AppendLine("$_") | Out-Null
  }
}
filter script:f-cnvp {
  Convert-Path $_ -ErrorAction 'Continue' 2>&1 | ForEach-Object {
    if ($_ -is [Management.Automation.ErrorRecord]) {
      $_.TargetObject
    }
    else {
      $_
    }
  }
}

filter script:f-template-key {
  param($add = @())
  Compare-Object (@() + $_.Keys) ($add + (Peek-Context).templates.Keys) `
    -PassThru -IncludeEqual -ExcludeDifferent # intersection
}

filter script:f-next-template-key {
  param($add = @(), $key)
  $clone = $_.Clone()
  $clone.Remove($key)
  $clone | f-template-key -a $add
}

filter script:f-is-list {
  ($_ -is [object[]]) -or ($_ -is [Collections.Generic.List[object]])
}

filter script:f-ps-creds {
  param([string]$user = 'token')
  [Management.Automation.PSCredential]::New($user, ("$_" | ConvertTo-SecureString -AsPlainText -Force))
}

filter script:f-wh-iex {
  Write-Host "$_"; &([scriptblock]::Create($_))
}

filter script:f-wh {
  param([ConsoleColor]$c = 'Gray')
  $Host.UI.WriteLine($c, [Console]::BackgroundColor, "$_")
}

filter global:f-wh-b {
  param([switch]$skip, [switch]$passthru)
  if ($skip) { return }
  $_ | f-wh -c 'Blue'
  if ($passthru) { $_ }
}

filter global:f-wh-c {
  param([switch]$skip, [switch]$passthru)
  if ($skip) { return }
  $_ | f-wh -c 'DarkCyan'
  if ($passthru) { $_ }
}

filter global:f-wh-g {
  param([switch]$skip, [switch]$passthru)
  if ($skip) { return }
  $_ | f-wh -c 'DarkGreen'
  if ($passthru) { $_ }
}

filter global:f-wh-m {
  param([switch]$skip, [switch]$passthru)
  if ($skip) { return }
  $_ | f-wh -c 'DarkMagenta'
  if ($passthru) { $_ }
}

filter global:f-wh-r {
  param([switch]$skip, [switch]$passthru)
  if ($skip) { return }
  $_ | f-wh -c 'DarkRed'
  if ($passthru) { $_ }
}

filter global:f-wh-y {
  param([switch]$skip, [switch]$passthru)
  if ($skip) { return }
  $_ | f-wh -c 'DarkYellow'
  if ($passthru) { $_ }
}

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

filter f-log-dbg {
  param([switch]$force, [ConsoleColor]$color = 'DarkYellow')
  if (("$(Peek-verbosity)" -eq 'Debug') -or $force) {
    "DEBUG: $_" | Log-Output -ForegroundColor $color | Out-Null
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
