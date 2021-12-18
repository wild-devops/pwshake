function f-tag-c { param($context, $next)
  Write-Host "`$next:c={$next}"
  "<c>$(&$next $context)</c>"
}
