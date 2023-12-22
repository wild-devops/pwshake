function f-tag-c { param($context, $next)
  Write-Host "`$next:c={$next}"
  "<c>$(&$next $context)</c>"
}

function Process-Step { param([Parameter(Mandatory, ValueFromPipeline)]$step, $next)
  switch ($step.Keys) {
    {$_ -eq 'on_error'} {  }
    {$_ -eq 'echo'} {
      &([scriptblock]::Create('Write-Host $step.$($_) -ForegroundColor Green')) *>&1 -ErrorVariable log-Err | Tee-Object -Variable log-Out | Write-Host -ForegroundColor DarkCyan
    }
    {$_ -eq 'pwsh'} {
      &([scriptblock]::Create($step.$($_))) *>&1 -ErrorVariable log-Err | Tee-Object -Variable log-Out
      Write-Host ${log-Out} -ForegroundColor Cyan
    }
    default {
        throw "Unknown step type: '$_'."
    }
  }
}

function Start-Pipeline { param([Parameter(Mandatory, ValueFromPipeline)]$context, $next)
  process {
    Write-Line "Start pipeline"
    Write-Host "`$context:`n$($_ | cty)" -ForegroundColor DarkGreen
    try {
      Get-Content -Path $context -Raw | cfy | &$next
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
}
