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
    ":In:" | f-log-dbg -skip # <<< skipped because of ${global:actor-context} doesn't exist yet
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
    finally {
      ":Out:" | f-log-dbg
    }
  }
  Process {
    ":In:" | f-log-dbg
    try {
      ${global:actor-context} | f-cty | Tee-Object -FilePath $PWD\actor-context.yaml `
        | f-cfy | ForEach-Object { $_.Remove('parent'); $_ } | % arguments | % ConfigPath | f-wh-b
      throw 'qu-qu'
    }
    catch {
      ":catch:" | f-log-dbg
      $_ | f-log-err
    }
    finally {
      ":Out:" | f-log-dbg
      ${global:actor-context} = ${global:actor-context}.parent
    }
  }
  End {
    ":In:" | f-log-dbg -skip # <<< skipped because of ${global:actor-context} always contains 'Debug' mode
    try {
      if ($null -eq ${global:actor-context}.parent) {
        'Remove-Variable -Name actor-context -Scope Global -Force' | f-wh-b -skip -passthru | Invoke-Expression
      }
    }
    catch {
      $_ | f-log-err
    }
    finally {
      ":Out:" | f-log-dbg -skip # <<< skipped because of ${global:actor-context} already doesn't exist
    }
  }
}
