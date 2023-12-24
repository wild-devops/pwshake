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
        arguments  = ($arguments + @{Tasks = $Tasks; WorkDir = "$(Get-Location)" })
        config     = Build-Config @arguments
        parent     = ${global:actor-context}
      }
    }
    catch {
      $_ | f-log-err
    }
  }
  Process {
    try {
      ${global:actor-context} | f-cty | Tee-Object -FilePath $PWD\actor-context.yaml `
      | f-cfy | % { $_.Remove('parent'); $_ } | f-cty | f-wh-m
    }
    catch {
      $_ | f-log-err
    }
    finally {
      try {
        ${global:actor-context} = ${global:actor-context}.parent
        if ($null -eq ${global:actor-context}.parent) {
          Remove-Item variable:'actor-context' -Force
        }
      }
      catch {
        $_ | f-log-err
      }
    }
  }
}
