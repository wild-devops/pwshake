function global:Coalesce {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [object[]]$values = $null
    )    
    process {
      if ($null -eq $values) {
          return $null
      }

      $result = $values -ne $null

      if ($null -eq $result) {
        return $null
      } elseif ($result) {
        return $result[0]
      } else {
        return $result
      }
    }
  }
