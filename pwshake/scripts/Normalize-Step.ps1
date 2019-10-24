function Normalize-Step {
    [CmdletBinding()]
    param (
      [Parameter(Position = 0, Mandatory = $false)]
      [object]$item,

      [Parameter(Position = 1, Mandatory = $false)]
      [hashtable]$config = @{}
    )    
    process {
        $ErrorActionPreference = "Stop"

        if (-not $item) { return $null }

        if ($item -is [string]) {
            $item = @{ name = $item; script = $item }
        } elseif ($item -is [Hashtable]) {
            if ($item.Keys.Length) {
                $key = $item.Keys | Select-Object -First 1
                $reserved_keys = @('name','script','powershell','cmd','template', 'parameters','when','invoke_tasks','work_dir','on_error')
                if ((-not ($key -in $reserved_keys)) -and ($item[$key] -is [hashtable])) {
                    $item = $item[$key]
                    $item.name = Coalesce $item.name, $key
                }
            }
        } else {
            throw "Unknown Task item type: $($item.GetType().Name)"
        }

        return @{
            name = Coalesce $item.name, "step_$([Math]::Abs($item.GetHashCode()))";
            when = (Normalize-When $item);
            work_dir = Coalesce $item.work_dir, $item.in;
            on_error = Coalesce $item.on_error, 'throw';
            script = $item.script;
            powershell = Coalesce $item.powershell, $item.pwsh;
            cmd = Coalesce $item.cmd, $item.shell;
            invoke_tasks = Coalesce $item.invoke_tasks, $item.apply_roles, $item.invoke_run_lists, @();
            template = $item.template;
            parameters = Coalesce $item.parameters, @{};
        }
    }
}
