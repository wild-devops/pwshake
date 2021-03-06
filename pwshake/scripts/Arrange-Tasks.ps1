function Arrange-Tasks {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    [object[]]$depends_on,

    [Parameter(Mandatory = $false)]
    [hashtable]$config = (Peek-Config),

    [Parameter(Mandatory = $false)]
    [int]$depth = 0
  )
  process {
    if ($depth -gt ${global:pwshake-context}.options.max_depth) {
      throw "Circular reference detected for dependant tasks in: $depends_on"
    }

    $tasks = @()

    foreach ($name in $depends_on) {
      "Arrange-Tasks:foreach:`$name:`n$(cty $name)" | f-log-dbg
      if (-not ($config.tasks.Keys -contains $name)) {
        throw "Task '$name' is undefined in the PWSHAKE config."
      }

      $task = Build-Task $config.tasks[$name] $name

      if ($task.depends_on) {
        $tasks += ($task.depends_on | Arrange-Tasks -depth ($depth + 1))
      }

      $tasks += $task
    }

    "Arrange-Tasks:Out:`$tasks:`n$(cty $tasks)" | f-log-dbg
    return $tasks
  }
}
