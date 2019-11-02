function Log-Output {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [object]$message,

      [Parameter(Position = 1, Mandatory = $true)]
      [hashtable]$config,

      [Parameter(Position = 2, Mandatory = $false)]
      [bool]$Rethrow = $false,

      [Parameter(Position = 3, Mandatory = $false)]
      [PwShake.VerbosityLevel]$Verbosity = [PwShake.VerbosityLevel]::Normal
  )    
    process {
        $level = Coalesce @(
            $config.attributes.pwshake_verbosity,
            ${pwshake-context}.verbosity,
            "Debug"
        )
        if (([PwShake.VerbosityLevel]$level) -lt $Verbosity) { return }

        $tmstmp = Get-Date -format "[yyyy-MM-dd HH:mm:ss]"

        if ($message -is [System.Management.Automation.ErrorRecord]) {
            if ($Rethrow) {
                $additionalInfo = "$tmstmp ERROR: $message" + `
                                  "`n$($message.InvocationInfo.PositionMessage)" + `
                                  "`n`t+ CategoryInfo : $($message.CategoryInfo.Category): ($($message.CategoryInfo.TargetName):$($message.CategoryInfo.TargetType)) [], $($message.CategoryInfo.Reason)" + `
                                  "`n`t+ FullyQualifiedErrorId : $($message.FullyQualifiedErrorId)"
                Add-Content -Path $config.attributes.pwshake_log_path -Value $additionalInfo -Encoding UTF8
                throw $message
            } else {
                Add-Content -Path $config.attributes.pwshake_log_path -Value "$tmstmp $message" -Encoding UTF8
                $Host.UI.WriteErrorLine("$message")
            }
        } else {
            Add-Content -Path $config.attributes.pwshake_log_path -Value "$tmstmp $message" -Encoding UTF8
            Write-Host $message
        }
    }
 }
