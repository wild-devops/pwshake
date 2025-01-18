function Validate-ScriptBlock {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
  [CmdletBinding()]
  [OutputType([scriptblock])]
  param (
    [Parameter(Mandatory,ValueFromPipeline)]
    [string]$name
  )
  ":In:$name" | f-log-dbg
  [scriptblock]$sb = $null; $ast = $null

  if ($name.Trim().StartsWith("{")) {
    $sb = [scriptblock]::Create($name.Trim().Trim('{','}'))
    ":In:`$" | f-log-dbg
    $ast = $sb.Ast
  }
  else {
    $sb = (Get-Item function:$name -ErrorAction SilentlyContinue).ScriptBlock
    $ast = $sb.Ast.Body
  }

  if ($null -eq $sb) {
    throw "'$name' is not found as function:$name."
  }

  switch (,$ast.ParamBlock.Parameters) {
    {$true} {
      ":$name`:switch-in: $_" | f-log-dbg
    }
    {$_.Count -ne 2} {
      ":$name`:throw-on: `$_.Count:$($_.Count)" | f-log-dbg
      throw "Pipeline function '$name': should contain exactly 2 parameters."
    }
    {$_[0].Name.VariablePath.UserPath -ne '@context'} {
      ":$name`:throw-on: `$_[0].Name.VariablePath:$($_[0].Name.VariablePath.UserPath)" | f-log-dbg
      throw "Pipeline function '$name': first parameter name should be '@context'."
    }
    {$_[1].Name.VariablePath.UserPath -ne '@next'} {
      ":$name`:throw-on: `$_[1].Name.VariablePath:$($_[1].Name.VariablePath.UserPath)" | f-log-dbg
      throw "Pipeline function '$name': second parameter name should be '@next'."
    }
    {$_[0].Attributes.Count -ne 2} {
      ":$name`:throw-on: `$_[0].Attributes.Count:$($_[0].Attributes.Count)" | f-log-dbg
      throw "Pipeline function '$name': first parameter should contain exactly 2 attributes ('Parameter', 'hashtable')."
    }
    {$_[1].Attributes.Count -ne 1} {
      ":$name`:throw-on: `$_[1].Attributes.Count:$($_[1].Attributes.Count)" | f-log-dbg
      throw "Pipeline function '$name': second parameter should contain exactly 1 attribute ('scriptblock')."
    }
    {"$($_[0].Attributes[1].TypeName)" -ne 'hashtable'} {
      ":$name`:throw-on: `$_[0].Attributes[1].TypeName:$($_[0].Attributes[1].TypeName)" | f-log-dbg
      throw "Pipeline function '$name': first parameter type attribute should be 'hashtable'."
    }
    {"$($_[1].Attributes[0].TypeName)" -ne 'scriptblock'} {
      ":$name`:throw-on: `$_[1].Attributes[0].TypeName:$($_[1].Attributes[0].TypeName)" | f-log-dbg
      throw "Pipeline function '$name': second parameter type attribute should be 'scriptblock'."
    }
    {"$($_[0].Attributes[0].TypeName)" -ne 'Parameter'} {
      ":$name`:throw-on: `$_[0].Attributes[0].TypeName:$($_[0].Attributes[0].TypeName)" | f-log-dbg
      throw "Pipeline function '$name': first parameter should contain 'Parameter' first attribute."
    }
    {$_[0].Attributes[0].NamedArguments.Count -ne 2} {
      ":$name`:throw-on: `$_[0].Attributes[0].NamedArguments.Count:$($_[0].Attributes[0].NamedArguments.Count)" | f-log-dbg
      throw "Pipeline function '$name': first 'Parameter' attribute should contain exactly 2 NamedArguments ('Mandatory', 'ValueFromPipeline')."
    }
    {$_[0].Attributes[0].NamedArguments[0].ArgumentName -ne 'Mandatory'} {
      ":$name`:throw-on: `$_[0].Attributes[0].NamedArguments[0].ArgumentName:$($_[0].Attributes[0].NamedArguments[0].ArgumentName)" | f-log-dbg
      throw "Pipeline function '$name': first attribute of NamedArguments should be 'Mandatory'."
    }
    {$_[0].Attributes[0].NamedArguments[1].ArgumentName -ne 'ValueFromPipeline'} {
      ":$name`:throw-on: `$_[0].Attributes[0].NamedArguments[1].ArgumentName:$($_[0].Attributes[0].NamedArguments[1].ArgumentName)" | f-log-dbg
      throw "Pipeline function '$name': second attribute of NamedArguments should be 'ValueFromPipeline'."
    }
    {(-not $_[0].Attributes[0].NamedArguments[0].ExpressionOmitted) -and ($_[0].Attributes[0].NamedArguments[0].Argument.Extent.Text -ne '$true') } {
      ":$name`:throw-on: `$_[0].Attributes[0].NamedArguments[0].ArgumentName:$($_[0].Attributes[0].NamedArguments[0].ArgumentName):$($_[0].Attributes[0].NamedArguments[0].Argument)" | f-log-dbg
      throw "Pipeline function '$name': 'Mandatory' attribute value should be '`$true' or empty."
    }
    {(-not $_[0].Attributes[0].NamedArguments[1].ExpressionOmitted) -and ($_[0].Attributes[0].NamedArguments[1].Argument.Extent.Text -ne '$true') } {
      ":$name`:throw-on: `$_[0].Attributes[0].NamedArguments[1].ArgumentName:$($_[0].Attributes[0].NamedArguments[1].ArgumentName):$($_[0].Attributes[0].NamedArguments[1].Argument)" | f-log-dbg
      throw "Pipeline function '$name': 'ValueFromPipeline' attribute value should be '`$true' or empty."
    }
    default {
      throw "Pipeline function '$name': should contain Parameters AST block."
    }
  }

  return $sb;
}
