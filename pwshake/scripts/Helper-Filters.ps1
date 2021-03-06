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
  param([Text.StringBuilder]$sb = (Peek-Context).json_sb)
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
