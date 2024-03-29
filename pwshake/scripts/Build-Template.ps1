function Build-Template {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
        [hashtable]$step,

        [Parameter(Position = 1, Mandatory = $false)]
        [hashtable]$config = (Coalesce (Peek-Config), @{}),

        [Parameter(Position = 2, Mandatory = $false)]
        [int]$depth = 0
    )
    process {
        "Build-Template:In:$(@{'$_'=$_} | ConvertTo-Yaml)" | f-log-dbg
        if ($null -eq $step) {
            return $null
        }
        else {
            $step = $step.Clone()
        }

        $template_key = Compare-Object (@() + $step.Keys) (@() + ${global:pwshake-context}.templates.Keys) `
            -PassThru -IncludeEqual -ExcludeDifferent # intersection
        "Build-Template:`$template_key = '$template_key'" | f-log-dbg
        if ($null -eq $template_key) {
            # not a template
            return $step
        }
        else {
            $step['$context'] = Coalesce $step['$context'], @{}
            $step['$context'].template_key = "$template_key"
        }

        if ($depth -gt ${global:pwshake-context}.options.max_depth) {
            "Build-Template:Circular-reference:`n$($step | ConvertTo-Yaml)" | f-log-dbg
            throw "Circular reference detected for template: $template_key"
        }

        $template = ${global:pwshake-context}.templates.$($template_key).Clone()
        $template = Merge-Hashtables $template $step # add step attributes
        if ($step.$($template_key) -is [hashtable]) {
            # move template attributes on step level
            $template.Remove($template_key)
            $template = Merge-Hashtables $template $step.$($template_key)
        }
        "Build-Template:Merge-Hashtables:$(@{'$template'=$template} | ConvertTo-Yaml)" | f-log-dbg
        $template = $template | Interpolate-Evals -template_key $template_key
        "Build-Template:Interpolate-Evals:$(@{'$template'=$template} | ConvertTo-Yaml)" | f-log-dbg

        if ($template.powershell) {
            "Build-Template:Out:$(@{'$template'=$template} | ConvertTo-Yaml)" | f-log-dbg
            return $template
        } else {
            $template.Remove($template_key) # to avoid double template keys search
            "Build-Template:Nest:$(@{'$template'=$template} | ConvertTo-Yaml)" | f-log-dbg
            return $template | Build-Template -depth ($depth + 1)
        }
    }
}
