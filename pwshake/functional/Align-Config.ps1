function Align-Config {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([hashtable])]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [hashtable]$config
  )
  Process {
    return @{
      includes             = @() + (Coalesce $config.includes, @());
      attributes           = Coalesce $config.attributes, @{};
      attributes_overrides = @() + (Coalesce $config.attributes_overrides, $config.environments, @());
      scripts_directories  = @() + (Coalesce $config.scripts_directories, @());
      tasks                = Coalesce $config.tasks, $config.run_lists, $config.roles, @{};
      invoke_tasks         = @() + (Coalesce $config.invoke_tasks, $config.invoke_run_lists, $config.apply_roles, @());
      templates            = Coalesce $config.templates, $config.actions, @{};
      resources            = @() + (Coalesce $config.resources, $config.repositories, @());
      filters              = Coalesce $config.filters, @{};
    }
  }
}
