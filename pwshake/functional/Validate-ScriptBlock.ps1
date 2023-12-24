function Validate-ScriptBlock {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([scriptblock])]
  param (
    [Parameter(Mandatory,ValueFromPipeline)]
    [string]$name
  )
  "Validate-ScriptBlock:In:$name" | f-log-dbg

  $sb = Get-Item function:$name -ErrorAction SilentlyContinue | ForEach-Object ScriptBlock
  if ($null -eq $sb) {
    throw "'$name' is not found as function:$name."
  }

  $ast = $sb.Ast.Body

  switch (,$ast.ParamBlock.Parameters) {
    {$true} {
      "Validate-ScriptBlock:$name`:switch-in: $_" | f-log-dbg
    }
    {$_.Count -ne 2} {
      "Validate-ScriptBlock:$name`:throw-on: `$_.Count:$($_.Count)" | f-log-dbg
      throw "Pipeline function '$name': should contain exactly 2 parameters."
    }
    {$_[0].Name.VariablePath.UserPath -ne '@context'} {
      "Validate-ScriptBlock:$name`:throw-on: `$_[0].Name.VariablePath:$($_[0].Name.VariablePath.UserPath)" | f-log-dbg
      throw "Pipeline function '$name': first parameter name should be '@context'."
    }
    {$_[1].Name.VariablePath.UserPath -ne '@next'} {
      "Validate-ScriptBlock:$name`:throw-on: `$_[1].Name.VariablePath:$($_[1].Name.VariablePath.UserPath)" | f-log-dbg
      throw "Pipeline function '$name': second parameter name should be '@next'."
    }
    {$_[0].Attributes.Count -ne 2} {
      "Validate-ScriptBlock:$name`:throw-on: `$_[0].Attributes.Count:$($_[0].Attributes.Count)" | f-log-dbg
      throw "Pipeline function '$name': first parameter should contain exactly 2 attributes ('Parameter', 'hashtable')."
    }
    {$_[1].Attributes.Count -ne 1} {
      "Validate-ScriptBlock:$name`:throw-on: `$_[1].Attributes.Count:$($_[1].Attributes.Count)" | f-log-dbg
      throw "Pipeline function '$name': second parameter should contain exactly 1 attribute ('scriptblock')."
    }
    {"$($_[0].Attributes[1].TypeName)" -ne 'hashtable'} {
      "Validate-ScriptBlock:$name`:throw-on: `$_[0].Attributes[1].TypeName:$($_[0].Attributes[1].TypeName)" | f-log-dbg
      throw "Pipeline function '$name': first parameter type attribute should be 'hashtable'."
    }
    {"$($_[1].Attributes[0].TypeName)" -ne 'scriptblock'} {
      "Validate-ScriptBlock:$name`:throw-on: `$_[1].Attributes[0].TypeName:$($_[1].Attributes[0].TypeName)" | f-log-dbg
      throw "Pipeline function '$name': second parameter type attribute should be 'scriptblock'."
    }
    {"$($_[0].Attributes[0].TypeName)" -ne 'Parameter'} {
      "Validate-ScriptBlock:$name`:throw-on: `$_[0].Attributes[0].TypeName:$($_[0].Attributes[0].TypeName)" | f-log-dbg
      throw "Pipeline function '$name': first parameter should contain 'Parameter' first attribute."
    }
    {$_[0].Attributes[0].NamedArguments.Count -ne 2} {
      "Validate-ScriptBlock:$name`:throw-on: `$_[0].Attributes[0].NamedArguments.Count:$($_[0].Attributes[0].NamedArguments.Count)" | f-log-dbg
      throw "Pipeline function '$name': first 'Parameter' attribute should contain exactly 2 NamedArguments ('Mandatory', 'ValueFromPipeline')."
    }
    {$_[0].Attributes[0].NamedArguments[0].ArgumentName -ne 'Mandatory'} {
      "Validate-ScriptBlock:$name`:throw-on: `$_[0].Attributes[0].NamedArguments[0].ArgumentName:$($_[0].Attributes[0].NamedArguments[0].ArgumentName)" | f-log-dbg
      throw "Pipeline function '$name': first attribute of NamedArguments should be 'Mandatory'."
    }
    {$_[0].Attributes[0].NamedArguments[1].ArgumentName -ne 'ValueFromPipeline'} {
      "Validate-ScriptBlock:$name`:throw-on: `$_[0].Attributes[0].NamedArguments[1].ArgumentName:$($_[0].Attributes[0].NamedArguments[1].ArgumentName)" | f-log-dbg
      throw "Pipeline function '$name': second attribute of NamedArguments should be 'ValueFromPipeline'."
    }
    {(-not $_[0].Attributes[0].NamedArguments[0].ExpressionOmitted) -and ($_[0].Attributes[0].NamedArguments[0].Argument.Extent.Text -ne '$true') } {
      "Validate-ScriptBlock:$name`:throw-on: `$_[0].Attributes[0].NamedArguments[0].ArgumentName:$($_[0].Attributes[0].NamedArguments[0].ArgumentName):$($_[0].Attributes[0].NamedArguments[0].Argument)" | f-log-dbg
      throw "Pipeline function '$name': 'Mandatory' attribute value should be '`$true' or empty."
    }
    {(-not $_[0].Attributes[0].NamedArguments[1].ExpressionOmitted) -and ($_[0].Attributes[0].NamedArguments[1].Argument.Extent.Text -ne '$true') } {
      "Validate-ScriptBlock:$name`:throw-on: `$_[0].Attributes[0].NamedArguments[1].ArgumentName:$($_[0].Attributes[0].NamedArguments[1].ArgumentName):$($_[0].Attributes[0].NamedArguments[1].Argument)" | f-log-dbg
      throw "Pipeline function '$name': 'ValueFromPipeline' attribute value should be '`$true' or empty."
    }
    default {
      throw "Pipeline function '$name': should contain Parameters AST block."
    }
  }

  return $sb;
}
