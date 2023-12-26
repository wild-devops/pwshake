enum VerbosityLevel {
    Quiet
    Error
    Warning
    Minimal
    Information
    Verbose
    Debug
    Normal  = 4
    Silent  = 0
    Default = 5
}

function Peek-Context {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param()
  $context = ${global:actor-context}
  while ($null -ne $context.parent) {
    $context = $context.parent
  }
  "Peek-Context:Out:`n$('$context' | f-vars-cty)" | f-wh-g
  return $context
}

function Peek-Config {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param()
  return ${global:actor-context}.config
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
  return [VerbosityLevel](Coalesce (Peek-Config).attributes.pwshake_verbosity, 'Default')
}
function Peek-LogPath {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param()
  return (Coalesce (Peek-Config).attributes.pwshake_log_path, ("$PWD/pwshake.log" | f-cnvp))
}

[scriptblock]${script:@next-stub} = {
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}
  )
  "@next-stub:`n`${@context}:${@context}`n`${@next}:${@next}" | f-log-dbg;
  if (${@next}) {&${@next} ${@context}} else {${@context}}
}

function script:$out-log-wh {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}
  )
  ${@context}.Value | f-wh
  "@script:$out-log-wh:Out:`${@context}.Value: $(${@context.Value})`n`${@next}:${@next}" | f-wh-m -s
  if (${@next}) { ${@context} | &${@next} } else { ${@context} }
}

function script:$log-out-min {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}
  )
  "@script:$log-out-min:In:`${@context}.Value: $(${@context.Value})`n`${@next}:${@next}" | f-wh-m -s
  if ((Peek-Verbosity) -ge [VerbosityLevel]'Minimal') {
    ${@context} = ${@context} | Log-Output
    if (${@next}) { ${@context} | &${@next} } else { ${@context} }
  }
}

function Reverse-Array {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param([Parameter(ValueFromPipeline)]$item)
  begin   {$array=@()}
  process {$array += $item}
  end     {[array]::Reverse($array);$array}
}

function f-vars-cty {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param([Parameter(ValueFromPipeline)][string]$var)
  begin   {$result=@()}
  process {$result+=@{"$var"=(Invoke-Expression $var)}}
  end     {,$result | f-cty}
}
