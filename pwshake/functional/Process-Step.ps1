function Process-Step {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}=${@next-stub}
  )
  "Process-Step:In:$(${@context}.name): $(${@context} | f-ctj-c)" | f-log-dbg

  $caption = "Execute step: $(${@context}.name)"
  ${on-step-header} = (Peek-Pipelines).$('$on-step-header') | Build-Pipeline
  $caption | f-build-context | &${on-step-header}

  try {
    &([scriptblock]::Create(${@context}.pwsh)) *>&1 | f-wh-m -p | f-log-min
  }
  catch {
    throw $_
  }
  finally {
    ${on-step-footer} = (Peek-Pipelines).$('$on-step-footer') | Build-Pipeline
    $caption | f-build-context | &${on-step-footer}
    ${@context} | &${@next}
  }
}
