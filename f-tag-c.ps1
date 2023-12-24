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
  Process {
    return $context | &$next
  }
}

function Process-Step {
  param([Parameter(Mandatory, ValueFromPipeline)]$step, $next)
  switch ($step.Keys) {
    { $_ -eq 'on_error' } {  }
    { $_ -eq 'echo' } {
      &([scriptblock]::Create('Write-Host $step.$($_) -ForegroundColor Green')) *>&1 -ErrorVariable log-Err | Tee-Object -Variable log-Out | Write-Host -ForegroundColor DarkCyan
    }
    { $_ -eq 'pwsh' } {
      &([scriptblock]::Create($step.$($_))) *>&1 -ErrorVariable log-Err | Tee-Object -Variable log-Out
      Write-Host ${log-Out} -ForegroundColor Cyan
    }
    default {
      throw "Unknown step type: '$_'"
    }
  }
}

function Start-Pipeline {
  param([Parameter(Mandatory, ValueFromPipeline)]$context, $next)
  process {
    Write-Line "Start pipeline"
    Write-Host "`$context:`n$($_ | f-cty)" -ForegroundColor DarkGreen
    try {
      Get-Content -Path $context -Raw | f-cfy | &$next
    }
    catch {
      $_.ScriptStackTrace.Split([Environment]::NewLine) | f-null | Select-Object -First 5 | ForEach-Object {
        "TRACE: $_" | ForEach-Object {
          $Host.UI.WriteLine([ConsoleColor]::Yellow, [Console]::BackgroundColor, $_)
        }
      }
      throw $_  
    }
  }
}

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
      ,@($context) | &$b -next $a }.GetNewClosure() }
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
