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
                $reserved_keys = @('name','script','powershell','cmd','msbuild','when','invoke_tasks','work_dir','on_error')
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
            script = $item.script;
            powershell = Coalesce $item.powershell, $item.pwsh, '';
            cmd = Coalesce $item.cmd, $item.shell, '';
            msbuild = (Normalize-MsBuild $item.msbuild $config);
            when = (Normalize-When $item);
            invoke_tasks = Coalesce $item.invoke_tasks, $item.apply_roles, $item.invoke_run_lists, @();
            work_dir = Coalesce $item.work_dir, $item.in, '';
            on_error = Coalesce $item.on_error, 'throw';
        }
    }
}
