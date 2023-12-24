$ErrorActionPreference = "Stop"

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
  if ((Peek-Verbosity) -ge [PWSHAKE.VerbosityLevel]'Minimal') {
    ${@context} = ${@context} | Log-Output
    if (${@next}) { ${@context} | &${@next} } else { ${@context} }
  }
}

function Array-Reverse {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param([Parameter(ValueFromPipeline)]$item)
  begin {$array=@()}
  process {$array += $item}
  end {[array]::Reverse($array);$array}
}

function global:f-vars-cty {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  param([Parameter(ValueFromPipeline)][string]$var)
  begin {$res=@()}
  process {$res+=@{$var="$(Invoke-Expression $var)"}}
  end {$res | cty}
}
