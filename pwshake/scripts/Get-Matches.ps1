function Get-Matches {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$string,

        [Parameter(Position = 1, Mandatory = $true)]
        [regex]$regex,

        [Parameter(Position = 2, Mandatory = $true)]
        [string]$group
    )
    $regex.Matches($string) `
      | Select-Object -ExpandProperty Groups `
      | Where-Object Name -eq $group `
      | Select-Object -ExpandProperty Value
  }
