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
      attributes           = Coalesce $config.attributes, @{};
      attributes_overrides = @() + (Coalesce $config.attributes_overrides, $config.environments, @());
      filters              = Coalesce $config.filters, @{};
      functions            = Coalesce $config.functions, @{};
      includes             = @() + (Coalesce $config.includes, @());
      invoke_tasks         = @() + (Coalesce $config.invoke_tasks, $config.invoke_run_lists, $config.apply_roles, @());
      resources            = @() + (Coalesce $config.resources, $config.repositories, @());
      scripts_directories  = @() + (Coalesce $config.scripts_directories, @());
      tasks                = Coalesce $config.tasks, $config.run_lists, $config.roles, @{};
      templates            = Coalesce $config.templates, $config.actions, @{};
    }
  }
}
