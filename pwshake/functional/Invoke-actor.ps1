function Invoke-actor {
  [CmdletBinding()]
  param (
    [Alias("Path", "File", "ConfigFile")]
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$ConfigPath = "$(Resolve-Path -Path pwshake.yaml -ErrorAction Stop)",

    [Parameter(Position = 1, Mandatory = $false)]
    [Alias("RunLists", "Roles")]
    [object[]]$Tasks = @(),

    [Alias("Attributes")]
    [Parameter(Position = 2, Mandatory = $false)]
    [object]$MetaData = $null,

    [Alias("LogLevel")]
    [ValidateSet('Error', 'Warning', 'Minimal', 'Information', 'Verbose', 'Debug', 'Normal', 'Default')]
    [Parameter(Mandatory = $false)]
    [string]$Verbosity = 'Normal',

    [Alias("WhatIf", "Noop")]
    [Parameter(Mandatory = $false)]
    [switch]$DryRun
  )
  Begin {
    "Invoke-actor:Begin:In:" | f-log-dbg
    try {
      if (-not ${global:actor-context}) {
        ${global:actor-context} = (Build-Context)
      }
      $arguments = @{
        ConfigPath = $ConfigPath
        MetaData   = $MetaData
        Verbosity  = $Verbosity
        DryRun     = [bool]$DryRun
      }
      ${global:actor-context} = @{
        arguments = ($arguments + @{Tasks = $Tasks; WorkDir = "$(Get-Location)" })
        config    = Build-Config @arguments
        parent    = ${global:actor-context}
      }
    }
    catch {
      $_ | f-log-err
    }
    "Invoke-actor:Begin:Out:`nvariable:\$('Get-Variable -Name actor-context -Scope Global -ErrorAction SilentlyContinue' | f-wh-b -skip -passthru | Invoke-Expression | % Name) = ${global:actor-context}" | f-log-dbg
  }
  Process {
    "Invoke-actor:Process:In:" | f-log-dbg
    try {
      ${global:actor-context} | f-cty | Tee-Object -FilePath $PWD\actor-context.yaml `
        | f-cfy | ForEach-Object { $_.Remove('parent'); $_ } | f-cty | f-wh-b
      throw 'qu-qu'
    }
    catch {
      $_ | f-log-err
    }
    finally {
      ${global:actor-context} = ${global:actor-context}.parent
    }
    "Invoke-actor:Process:Out:`nvariable:\$('Get-Variable -Name actor-context -Scope Global -ErrorAction SilentlyContinue' | f-wh-b -skip -passthru | Invoke-Expression | % Name) = ${global:actor-context}" | f-log-dbg
  }
  End {
    "Invoke-actor:End:In:`nvariable:\$('Get-Variable -Name actor-context -Scope Global -ErrorAction SilentlyContinue' | f-wh-b -skip -passthru | Invoke-Expression | % Name) = ${global:actor-context}" | f-log-dbg
    try {
      if ($null -eq ${global:actor-context}.parent) {
        'Remove-Variable -Name actor-context -Scope Global -Force' | f-wh-b -skip -passthru | Invoke-Expression
      }
    }
    catch {
      $_ | f-log-err
    }
    "Invoke-actor:End:Out:`nvariable:\$('Get-Variable -Name actor-context -Scope Global -ErrorAction SilentlyContinue' | f-wh-b -skip -passthru | Invoke-Expression | % Name) = ${global:actor-context}" | f-log-dbg
  }
}
