function Build-Pipeline {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([scriptblock])]
  param (
    [Parameter(Mandatory,ValueFromPipeline)]
    [string]$name
  )
  Begin {
    [scriptblock[]]$pipeline = @(${@next-stub})
    "@Build-Pipeline:Begin:`n`$pipeline:$pipeline" | f-wh-m -s
    $i = 0
  }
  Process {
    [scriptblock]$next = $name | Validate-ScriptBlock
    $pipeline += $next
    "@Build-Pipeline:Process:$i`:`n`$pipeline:$pipeline`n`$next:$next" | f-wh-m -s
    $i+=1
  }
  End {
    $pipeline += {
      param([Parameter(Mandatory, ValueFromPipeline)][hashtable]${@context},[scriptblock]${@next})
      "@end-pipeline:`n`$args:$args" | f-wh-m -s
    }
    [array]::Reverse($pipeline)
    $result = $pipeline | Reduce-Object -Reducer {param($a, $b)
      {
        param([Parameter(Mandatory, ValueFromPipeline)][hashtable]${@context},[scriptblock]${@next})
        "@reducer:`n`${@context}:${@context}`n`$a:$a`n`$b:$b" | f-wh-m -s
        $splat = @{'@context'=${@context};'@next'=$a}
        &$b @splat
      }.GetNewClosure()
    }
    "@Build-Pipeline:End:$i`:`n`$result:$result" | f-wh-m -s
    $result
  }
}
