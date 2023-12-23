function NullFormat {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [object]$value = $null,

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$format = '$_'
  )    
  process {
    if ($null -eq $value) {
      return $null
    }
      
    $value | ForEach-Object { "$($format -replace '\$_', $value)" }
  }
}
