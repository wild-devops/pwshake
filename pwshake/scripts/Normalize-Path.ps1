function Normalize-Path {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$path,

    [Parameter(Position = 1, Mandatory = $false)]
    [hashtable]$config = @{}
  )    
  process {
      $ErrorActionPreference = "Stop"
      if (-not $path) {
          return $null
      }

      if (Test-Path $path) {
          $path = "$(Resolve-Path $path)"
      } elseif (($config.attributes.work_dir) -and
                  (Test-Path (Join-Path -Path $config.attributes.work_dir -ChildPath $path))) {
          $path = "$(Join-Path -Path $config.attributes.work_dir -ChildPath $path)"
      } elseif (($config.attributes.pwshake_path) -and
                  (Test-Path (Join-Path -Path $config.attributes.pwshake_path -ChildPath $path))) {
          $path = "$(Join-Path -Path $config.attributes.pwshake_path -ChildPath $path)"
      } else {
          throw "Unknown path: $path"      
      }

      return $path
  }
}
