function Normalize-Config {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline= $true)]
        [hashtable]$config
    )
    process {
        $templates = Coalesce $config.templates, @{}
        ${pwshake-context}.templates = Merge-Hashtables ${pwshake-context}.templates $templates
        return @{
            includes = @() + (Coalesce $config.includes,  @());
            attributes = Coalesce $config.attributes, @{};
            attributes_overrides = @() + (Coalesce $config.attributes_overrides,  @());
            scripts_directories = @() + (Coalesce $config.scripts_directories, @());
            tasks = Coalesce $config.tasks, $config.tasks, $config.roles, @{};
            templates = $templates;
            invoke_tasks = @() + (Coalesce $config.invoke_tasks, $config.invoke_run_lists, $config.apply_roles,  @());
        }
    }
}