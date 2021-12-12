function Log-Output {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [object]$message,

      [Parameter(Position = 1, Mandatory = $false)]
      [hashtable]$config = (Coalesce (Peek-Config), @{}),

      [Parameter(Mandatory = $false)]
      [string]$ForegroundColor = $null
  )
    process {
        if ((Peek-Verbosity) -eq [PWSHAKE.VerbosityLevel]::Quiet) { return }

        $message = "$message" | f-mask-secured
        $message | f-tmstmp | Add-Content -Path $config.attributes.pwshake_log_path
        if ($_ -is [Management.Automation.ErrorRecord]) {
            $Host.UI.WriteLine([ConsoleColor]"Red",[Console]::BackgroundColor,$message)
        } else {
            if ($ForegroundColor) {
                $Host.UI.WriteLine([ConsoleColor]"$ForegroundColor",[Console]::BackgroundColor,$message)
            } else {
                $Host.UI.WriteLine($message)
            }
        }
        $message
    }
}
