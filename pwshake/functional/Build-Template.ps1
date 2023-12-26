function Build-Template {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [hashtable]$step,
    [Parameter(Position = 1, Mandatory = $false)]
    [hashtable]$config = (Peek-Config),
    [Parameter(Position = 2, Mandatory = $false)]
    [int]$depth = 0,
    [Parameter(Position = 3, Mandatory = $false)]
    [string]$template_key = $null
  )
  process {
    ":In:" | f-log-dbg '$depth', '$_'

    if ($depth -gt (Peek-Options).max_depth) {
      throw "Circular reference detected for template: $template_key"
    }

    if ($null -eq $step) {
      $null
      $null
      return
    } else {
      $step = $step.Clone()
    }

    if (-not $template_key) { # $template_key is not passed from the caller
      $template_key = $step | f-template-key
    }

    if (-not $template_key) { # $step is not a template
      $step
      $null
      return
    }
    ################ the rest of code is only for templates processing

    $template = $origin_template = (Peek-Context).templates.$($template_key).Clone() | ForEach-Object {
      if ($_.pwsh) { # clean up shortcuts
        $_.powershell = $_.pwsh; $_.Remove('pwsh')
      }
      $_
    }

    $step_content, $step_template_content = $step | f-split-by-key -k $template_key
    "Build-Template:$depth`:$template_key`:Split:`n$(@{'$step_content'=$step_content;`
      '$step_template_content'=$step_template_content} | cty)" | f-log-dbg

    switch (,$step_template_content) {
      {[string]::IsNullOrEmpty("$_")} {
        '$null' | f-log-dbg
        $template.Remove($template_key)
        break;
      }
      {$_.GetType() -in @([string], [object[]], [Collections.Generic.List[object]])} {
        '[string], ...' | f-log-dbg
        $template = $template, @{$template_key=$step_template_content} | Merge-Object -Strategy Override
      }
      {$_ -is [hashtable]} {
        '[hashtable]' | f-log-dbg
        $template = $template, $step_template_content | Merge-Object -Strategy Override
      }
      default {
        throw "Wrong type of $template content: '$($_.GetType().FullName)'."
      }
    }
    $template = $template, $step_content | Merge-Object -Strategy Override
    "Build-Template:$depth`:$template_key`:Merge-Object:`n$(@{'$template'=$template} | cty)" | f-log-dbg

    $template = $template | Interpolate-Evals -template_key $template_key
    "Build-Template:$depth`:$template_key`:Interpolate-Evals:`n$(@{'$template'=$template} | cty)" | f-log-dbg

    if ($template.powershell) { # exit from recursion
      "Build-Template:$depth`:$template_key`:End:`n$(@{'$template'=$template} | cty)" | f-log-dbg
      $template; $template_key
      return
    }
    else { # enter to recursion
      $template.Remove($template_key) # to find next key
      $next_template_key = $template | f-template-key
      $origin_template.Remove($next_template_key) # to keep nested template on subtraction
      $next = $template | f-subtract -s $origin_template # clean up prev template items
      "Build-Template:$depth`:$next_template_key`:Next:`n$(@{'$next'=$next} | cty)" | f-log-dbg
      $next | Build-Template -depth ($depth + 1) -template_key $next_template_key
      return
    }

    throw 'Something went wrong...' # we have not expected be here
  }
}
