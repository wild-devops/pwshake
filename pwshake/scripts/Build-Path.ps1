function Build-Path {
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [string]$path,

    [Parameter(Position = 1, Mandatory = $false)]
    [hashtable]$config = (Coalesce (Peek-Config), @{}),

    [Parameter(Mandatory = $false)]
    [switch]$Unresolved
  )
  process {
    "Build-Path:In:`$path = $path" | f-dbg
    if (-not $path) {
      return $null
    }

    if (Test-Path $path) {
      $path = "$(Convert-Path $path)"
    }
    elseif (Test-Path (Join-Path -Path $config.attributes.work_dir -ChildPath $path)) {
      $path = "$(Join-Path -Path $config.attributes.work_dir -ChildPath $path)"
    }
    elseif (Test-Path (Join-Path -Path $config.attributes.pwshake_path -ChildPath $path)) {
      $path = "$(Join-Path -Path $config.attributes.pwshake_path -ChildPath $path)"
    }
    else {
      if (!$Unresolved) {
        throw "Unknown path: $path"
      }
      else {
        if ([IO.Path]::GetPathRoot($path) -notin [IO.Directory]::GetLogicalDrives()) {
          $path = Join-Path $config.attributes.pwshake_path $path
        }
        elseif (${is-Linux} -and ($path -notmatch '^/.*')) {
          $path = Join-Path $config.attributes.pwshake_path $path
        }
        $path = "$($path | f-cnvp)"
      }
    }

    "Build-Path:Out:`$path = $path" | f-dbg
    return $path
  }
}
