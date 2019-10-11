function Normalize-Task {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [object]$item,

      [Parameter(Position = 1, Mandatory = $false)]
      [object]$name = "task_$([Math]::Abs((Get-Date).GetHashCode()))"
    )    
    process {
        $ErrorActionPreference = "Stop"

        if (-not $item) {
            return @{
              name = $name;
              steps = @();
              depends_on = @();
              when = "`$true";
              work_dir = '';
            }
        }

        if (($item -is [Collections.Generic.List[Object]]) -or
            ($item -is [object[]])) {
          $item = @{ name = $name; steps = $item }
        } elseif (-not ($item -is [hashtable])) {
          throw "Unknown tasks item type: $($item.GetType().Name)"
        }

        return @{
          name = Coalesce $item.name, $name;
          steps = Coalesce $item.steps, $item.scripts, @();
          depends_on = Coalesce $item.depends_on, @();
          when = (Normalize-When $item);
          work_dir = Coalesce $item.work_dir, $item.in, '';
        }
    }
}
