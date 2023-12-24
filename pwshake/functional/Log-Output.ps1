function Log-Output {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]${@context},
    [scriptblock]${@next}=${@next-stub}
  )
  Process {
    $ErrorActionPreference = "Stop"
    $message = ${@context}.Value
    $ForegroundColor = ${@context}.ForegroundColor
    "@Log-Output:In:`n$('$message', '${@next}' | f-vars-cty)" | f-wh-y -s
    if ((Peek-Verbosity) -eq [PWSHAKE.VerbosityLevel]::Quiet) { return }

    $message = "${message}" | f-mask-secured
    if ($_ -is [Management.Automation.ErrorRecord]) {
      $Host.UI.WriteLine([ConsoleColor]"Red",[Console]::BackgroundColor,$message)
    } else {
      if ($ForegroundColor) {
        $Host.UI.WriteLine([ConsoleColor]"$ForegroundColor",[Console]::BackgroundColor,$message)
      } else {
        $Host.UI.WriteLine($message)
      }
    }
    foreach ($item in ${pwshake-context}.invocations) {
      $message | f-tmstmp | Add-Content -Path $item.config.attributes.pwshake_log_path
    }
    $message | f-build-context | &${@next}
  }
}
