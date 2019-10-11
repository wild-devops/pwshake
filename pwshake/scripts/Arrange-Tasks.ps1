function Arrange-Tasks {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true)]
    [hashtable]$config,

    [Parameter(Position = 1, Mandatory = $false)]
    [object[]]$depends_on = $config.invoke_tasks,

    [Parameter(Position = 2, Mandatory = $false)]
    [int]$depth = 0
  )
  process {
    if ($depth -gt 100) {
      throw "Circular reference detected for dependant tasks in: $depends_on"
    }

    $tasks = @()

    foreach ($name in $depends_on) {
      if (-not ($config.tasks.Keys -contains $name)) {
        throw "Task '$name' is undefined in the PWSHAKE config."
      }

      $task = Normalize-Task $config.tasks[$name] $name

      if ($task.depends_on) {
        $tasks += (Arrange-Tasks $config $task.depends_on ($depth + 1))
      }

      $tasks += $task
    }

    return $tasks
  }
}
