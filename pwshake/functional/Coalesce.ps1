function Coalesce {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [object[]]$values = $null
  )  
  Process {
    if ($null -eq $values) {
      return $null
    }

    $result = $values -ne $null # <<< this filters input array elements, but not compares to $null

    if ($null -eq $result) {
      return $null
    }
    elseif ($result) {
      return $result[0]
    }
    else {
      return $result
    }
  }
}
 
# $x = @{a = "b"; c = "d" }
# "not null: $(Coalesce $x.in, $x.out, $x.c)"
# "not null: $((Coalesce $x.in, $x.out, @()).GetType())"
# "null: $(Coalesce $x.in, $x.out, $x.abs)"
# "null: $(Coalesce $null)"