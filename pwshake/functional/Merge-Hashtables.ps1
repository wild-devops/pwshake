function Merge-Hashtables
{
    [CmdletBinding()]
    param (
        #Identifies the first hashtable
        [Parameter(Position = 0, Mandatory = $true)]
        [hashtable]$First,

        #Identifies the second hashtable
        [Parameter(Position = 1, Mandatory = $true)]
        [hashtable]$Second
    )

    function Set-Keys ($First, $Second)
    {
        @($First.Keys) | Where-Object {
            $Second.ContainsKey($_)
        } | ForEach-Object {
            $key = $_
            if (($First.$_ -is [Hashtable]) -and ($Second.$_ -is [Hashtable]))
            {
                Set-Keys -First $First.$_ -Second $Second.$_
            } elseif (($First.$_ -is [Collections.Generic.List[Object]]) -or ($First.$_ -is [object[]])) {
                $First.$_ += ($Second.$_ | Where-Object {$First.$key -notcontains $_})
            } else {
                $First.$_ = $Second.$_
            }
        }
    }

    function Add-Keys ($First, $Second)
    {
        @($Second.Keys) | ForEach-Object {
            if ($First.ContainsKey($_))
            {
                if (($Second.$_ -is [Hashtable]) -and ($First.$_ -is [Hashtable]))
                {
                    Add-Keys -First $First.$_ -Second $Second.$_
                }
            }
            else
            {
                $First.Add($_, $Second.$_)
            }
        }
    }

    # Do not touch the original hashtables
    $firstClone  = $First.Clone()
    $secondClone = $Second.Clone()

    # Bring modified keys from secondClone to firstClone
    Set-Keys -First $firstClone -Second $secondClone

    # Bring additional keys from secondClone to firstClone
    Add-Keys -First $firstClone -Second $secondClone

    # return firstClone
    $firstClone
}
