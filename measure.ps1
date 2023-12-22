using namespace System.Management.Automation.Language
#region Profiler
class Profiler
{
    [System.Diagnostics.Stopwatch[]]$StopWatches
    Profiler([IScriptExtent]$extent)
    {
        $lines = $extent.EndLineNumber
        $this.StopWatches = [System.Diagnostics.Stopwatch[]]::new($lines)
        for ($i = 0; $i -lt $lines; $i++)
        {
            $this.StopWatches[$i] = [System.Diagnostics.Stopwatch]::new()
        }
    }

    [void] StartLine([int] $lineNo)
    {        
        $this.StopWatches[$lineNo].Start()
    }

    [void] EndLine([int] $lineNo)
    {
        $this.StopWatches[$lineNo].Stop()
    }
}
#endregion

#region AstVisitor 
class AstVisitor : ICustomAstVisitor
{
    [Profiler]$Profiler = $null
    AstVisitor([Profiler]$profiler) {
        $this.Profiler = $profiler
    }
    [System.Object] VisitElement([object]$element) {
        if ($element -eq $null) {
            return $null
        }
        $res = $element.Visit($this)
        return $res
    }
    [System.Object] VisitElements([System.Object]$elements) {
            if ($elements -eq $null -or $elements.Count -eq 0)
            {
                return $null
            }
            $typeName = $elements.gettype().GenericTypeArguments.Fullname

            $newElements = New-Object -TypeName "System.Collections.Generic.List[$typeName]"
            foreach($element in $elements) {
                $visitedResult = $element.Visit($this)
                $newElements.add($visitedResult)
            }
            return $newElements 
    }
    [StatementAst[]] VisitStatements([object]$Statements)
    {
            $newStatements = [System.Collections.Generic.List[StatementAst]]::new()
            foreach ($statement in $statements)
            {
                # [bool]$instrument = $statement -is [PipelineBaseAst]
                # $extent = $statement.Extent
                # if ($instrument)
                # {
                #     $expressionAstCollection = [System.Collections.Generic.List[ExpressionAst]]::new()
                #     $constantExpression = [ConstantExpressionAst]::new($extent, $extent.StartLineNumber - 1)
                #     $expressionAstCollection.Add($constantExpression)
                #     $constantProfiler = [ConstantExpressionAst]::new($extent, $this.Profiler)
                #     $constantStartline = [StringConstantExpressionAst]::new($extent, "StartLine", [StringConstantType]::BareWord)
                #     $invokeMember = [InvokeMemberExpressionAst]::new(
                #             $extent,
                #             $constantProfiler,
                #             $constantStartline,
                #             $expressionAstCollection,
                #             $false
                #         )
                #     $startLine = [CommandExpressionAst]::new(
                #         $extent, 
                #         $invokeMember, 
                #         $null
                #     )
                #     $pipe = [PipelineAst]::new($extent, $startLine);
                #     $newStatements.Add($pipe)
                # }
                $newStatements.Add($this.VisitElement($statement))
                # if ($instrument)
                # {
                #     $expressionAstCollection = [System.Collections.Generic.List[ExpressionAst]]::new()
                #     $expressionAstCollection.Add([ConstantExpressionAst]::new($extent, $extent.StartLineNumber - 1))
                #     $endLine = [CommandExpressionAst]::new(
                #         $extent, 
                #         [InvokeMemberExpressionAst]::new(
                #             $extent,
                #             [ConstantExpressionAst]::new($extent, $this.Profiler),
                #             [StringConstantExpressionAst]::new($extent, "EndLine", [StringConstantType]::BareWord),
                #             $expressionAstCollection, 
                #             $false
                #         ), 
                #         $null
                #     )
                #     $pipe = [PipelineAst]::new($extent, $endLine)
                #     $newStatements.add($pipe)
                # }
            }
            return $newStatements
        }

    [system.object] VisitScriptBlock([ScriptBlockAst] $scriptBlockAst)
    {
        $newParamBlock = $this.VisitElement($scriptBlockAst.ParamBlock)
        $newBeginBlock = $this.VisitElement($scriptBlockAst.BeginBlock)
        $newProcessBlock = $this.VisitElement($scriptBlockAst.ProcessBlock)
        $newEndBlock = $this.VisitElement($scriptBlockAst.EndBlock)
        $newDynamicParamBlock = $this.VisitElement($scriptBlockAst.DynamicParamBlock)
        return [ScriptBlockAst]::new($scriptBlockAst.Extent, $newParamBlock, $newBeginBlock, $newProcessBlock, $newEndBlock, $newDynamicParamBlock)
    }


    [system.object] VisitNamedBlock([NamedBlockAst] $namedBlockAst)
    {
        $newTraps = $this.VisitElements($namedBlockAst.Traps)
        $newStatements = $this.VisitStatements($namedBlockAst.Statements)
        $statementBlock = [StatementBlockAst]::new($namedBlockAst.Extent,$newStatements,$newTraps)
        return [NamedBlockAst]::new($namedBlockAst.Extent, $namedBlockAst.BlockKind, $statementBlock, $namedBlockAst.Unnamed)
    }

    [system.object] VisitFunctionDefinition([FunctionDefinitionAst] $functionDefinitionAst)
    {
        $newBody = $this.VisitElement($functionDefinitionAst.Body)
        return [FunctionDefinitionAst]::new($functionDefinitionAst.Extent, $functionDefinitionAst.IsFilter,$functionDefinitionAst.IsWorkflow, $functionDefinitionAst.Name, $this.VisitElements($functionDefinitionAst.Parameters), $newBody);
    }

    [system.object] VisitStatementBlock([StatementBlockAst] $statementBlockAst)
    {
        $newStatements = $this.VisitStatements($statementBlockAst.Statements)
        $newTraps = $this.VisitElements($statementBlockAst.Traps)
        return [StatementBlockAst]::new($statementBlockAst.Extent, $newStatements, $newTraps)
    }

    [system.object] VisitIfStatement([IfStatementAst] $ifStmtAst)
    {
        $newClauses = $ifStmtAst.Clauses | ForEach-Object {
            $newClauseTest = $this.VistitElement($_.Item1)
            $newStatementBlock = $this.VistitElement($_.Item2)
            [System.Tuple[PipelineBaseAst,StatementBlockAst]]::new($newClauseTest,$newStatementBlock)
        }
        $newElseClause = $this.VisitElement($ifStmtAst.ElseClause)
        return [IfStatementAst]::new($ifStmtAst.Extent, $newClauses, $newElseClause)
    }

    [system.object] VisitTrap([TrapStatementAst] $trapStatementAst)
    {
        return [TrapStatementAst]::new($trapStatementAst.Extent, $this.VisitElement($trapStatementAst.TrapType), $this.VisitElement($trapStatementAst.Body))
    }

    [system.object] VisitSwitchStatement([SwitchStatementAst] $switchStatementAst)
    {
        $newCondition = $this.VisitElement($switchStatementAst.Condition)
        $newClauses = $switchStatementAst.Clauses | ForEach-Object {
            $newClauseTest = $this.VistitElement($_.Item1)
            $newStatementBlock = $this.VistitElement($_.Item2)
            [System.Tuple[ExpressionAst,StatementBlockAst]]::new($newClauseTest,$newStatementBlock)
        }
        $newDefault = $this.VisitElement($switchStatementAst.Default)
        return [SwitchStatementAst]::new($switchStatementAst.Extent, $switchStatementAst.Label,$newCondition,$switchStatementAst.Flags, $newClauses, $newDefault)
    }

    [system.object] VisitDataStatement([DataStatementAst] $dataStatementAst)
    {
        $newBody = $this.VisitElement($dataStatementAst.Body)
        $newCommandsAllowed = $this.VisitElements($dataStatementAst.CommandsAllowed)
        return [DataStatementAst]::new($dataStatementAst.Extent, $dataStatementAst.Variable, $newCommandsAllowed, $newBody)
    }

    [system.object] VisitForEachStatement([ForEachStatementAst] $forEachStatementAst)
    {
        $newVariable = $this.VisitElement($forEachStatementAst.Variable)
        $newCondition = $this.VisitElement($forEachStatementAst.Condition)
        $newBody = $this.VisitElement($forEachStatementAst.Body)
        return [ForEachStatementAst]::new($forEachStatementAst.Extent, $forEachStatementAst.Label, [ForEachFlags]::None, $newVariable, $newCondition, $newBody)
    }

    [system.object] VisitDoWhileStatement([DoWhileStatementAst] $doWhileStatementAst)
    {
        $newCondition = $this.VisitElement($doWhileStatementAst.Condition)
        $newBody = $this.VisitElement($doWhileStatementAst.Body)
        return [DoWhileStatementAst]::new($doWhileStatementAst.Extent, $doWhileStatementAst.Label, $newCondition, $newBody)
    }

    [system.object] VisitForStatement([ForStatementAst] $forStatementAst)
    {
        $newInitializer = $this.VisitElement($forStatementAst.Initializer)
        $newCondition = $this.VisitElement($forStatementAst.Condition)
        $newIterator = $this.VisitElement($forStatementAst.Iterator)
        $newBody = $this.VisitElement($forStatementAst.Body)
        return [ForStatementAst]::new($forStatementAst.Extent, $forStatementAst.Label, $newInitializer, $newCondition, $newIterator, $newBody)
    }

    [system.object] VisitWhileStatement([WhileStatementAst] $whileStatementAst)
    {
        $newCondition = $this.VisitElement($whileStatementAst.Condition)
        $newBody = $this.VisitElement($whileStatementAst.Body)
        return [WhileStatementAst]::new($whileStatementAst.Extent, $whileStatementAst.Label, $newCondition, $newBody)
    }

    [system.object] VisitCatchClause([CatchClauseAst] $catchClauseAst)
    {
        $newBody = $this.VisitElement($catchClauseAst.Body)
        return [CatchClauseAst]::new($catchClauseAst.Extent, $catchClauseAst.CatchTypes, $newBody)
    }

    [system.object] VisitTryStatement([TryStatementAst] $tryStatementAst)
    {
        $newBody = $this.VisitElement($tryStatementAst.Body)
        $newCatchClauses = $this.VisitElements($tryStatementAst.CatchClauses)
        $newFinally = $this.VisitElement($tryStatementAst.Finally)
        return [TryStatementAst]::new($tryStatementAst.Extent, $newBody, $newCatchClauses, $newFinally)
    }

    [system.object] VisitDoUntilStatement([DoUntilStatementAst] $doUntilStatementAst)
    {
        $newCondition = $this.VisitElement($doUntilStatementAst.Condition)
        $newBody = $this.VisitElement($doUntilStatementAst.Body)
        return [DoUntilStatementAst]::new($doUntilStatementAst.Extent, $doUntilStatementAst.Label, $newCondition, $newBody)
    }

    [system.object] VisitParamBlock([ParamBlockAst] $paramBlockAst)
    {
        $newAttributes = $this.VisitElements($paramBlockAst.Attributes)
        $newParameters = $this.VisitElements($paramBlockAst.Parameters)
        return [ParamBlockAst]::new($paramBlockAst.Extent, $newAttributes, $newParameters)
    }

    [system.object] VisitErrorStatement([ErrorStatementAst] $errorStatementAst)
    {
        return $errorStatementAst
    }

    [system.object] VisitErrorExpression([ErrorExpressionAst] $errorExpressionAst)
    {
        return $errorExpressionAst
    }

    [system.object] VisitTypeConstraint([TypeConstraintAst] $typeConstraintAst)
    {
        return [TypeConstraintAst]::new($typeConstraintAst.Extent, $typeConstraintAst.TypeName)
    }

    [system.object] VisitAttribute([AttributeAst] $attributeAst)
    {
        $newPositionalArguments = $this.VisitElements($attributeAst.PositionalArguments)
        $newNamedArguments = $this.VisitElements($attributeAst.NamedArguments)
        return [AttributeAst]::new($attributeAst.Extent, $attributeAst.TypeName, $newPositionalArguments, $newNamedArguments)
    }

    [system.object] VisitNamedAttributeArgument([NamedAttributeArgumentAst] $namedAttributeArgumentAst)
    {
        $newArgument = $this.VisitElement($namedAttributeArgumentAst.Argument)
        return [NamedAttributeArgumentAst]::new($namedAttributeArgumentAst.Extent, $namedAttributeArgumentAst.ArgumentName, $newArgument,$namedAttributeArgumentAst.ExpressionOmitted)
    }

    [system.object] VisitParameter([ParameterAst] $parameterAst)
    {
        $newName = $this.VisitElement($parameterAst.Name)
        $newAttributes = $this.VisitElements($parameterAst.Attributes)
        $newDefaultValue = $this.VisitElement($parameterAst.DefaultValue)
        return [ParameterAst]::new($parameterAst.Extent, $newName, $newAttributes, $newDefaultValue)
    }

    [system.object] VisitBreakStatement([BreakStatementAst] $breakStatementAst)
    {
        $newLabel = $this.VisitElement($breakStatementAst.Label)
        return [BreakStatementAst]::new($breakStatementAst.Extent, $newLabel)
    }

    [system.object] VisitContinueStatement([ContinueStatementAst] $continueStatementAst)
    {
        $newLabel = $this.VisitElement($continueStatementAst.Label)
        return [ContinueStatementAst]::new($continueStatementAst.Extent, $newLabel)
    }

    [system.object] VisitReturnStatement([ReturnStatementAst] $returnStatementAst)
    {
        $newPipeline = $this.VisitElement($returnStatementAst.Pipeline)
        return [ReturnStatementAst]::new($returnStatementAst.Extent, $newPipeline)
    }

    [system.object] VisitExitStatement([ExitStatementAst] $exitStatementAst)
    {
        $newPipeline = $this.VisitElement($exitStatementAst.Pipeline)
        return [ExitStatementAst]::new($exitStatementAst.Extent, $newPipeline)
    }

    [system.object] VisitThrowStatement([ThrowStatementAst] $throwStatementAst)
    {
        $newPipeline = $this.VisitElement($throwStatementAst.Pipeline)
        return [ThrowStatementAst]::new($throwStatementAst.Extent, $newPipeline)
    }

    [system.object] VisitAssignmentStatement([AssignmentStatementAst] $assignmentStatementAst)
    {
        $newLeft = $this.VisitElement($assignmentStatementAst.Left)
        $newRight = $this.VisitElement($assignmentStatementAst.Right)
        return [AssignmentStatementAst]::new($assignmentStatementAst.Extent, $newLeft, $assignmentStatementAst.Operator,$newRight, $assignmentStatementAst.ErrorPosition)
    }

    [system.object] VisitPipeline([PipelineAst] $pipelineAst)
    {
        $newPipeElements = $this.VisitElements($pipelineAst.PipelineElements)
        return [PipelineAst]::new($pipelineAst.Extent, $newPipeElements)
    }

    [system.object] VisitCommand([CommandAst] $commandAst)
    {
        $newCommandElements = $this.VisitElements($commandAst.CommandElements)
        $newRedirections = $this.VisitElements($commandAst.Redirections)
        return [CommandAst]::new($commandAst.Extent, $newCommandElements, $commandAst.InvocationOperator, $newRedirections)
    }

    [system.object] VisitCommandExpression([CommandExpressionAst] $commandExpressionAst)
    {
        $newExpression = $this.VisitElement($commandExpressionAst.Expression)
        $newRedirections = $this.VisitElements($commandExpressionAst.Redirections)
        return [CommandExpressionAst]::new($commandExpressionAst.Extent, $newExpression, $newRedirections)
    }

    [system.object] VisitCommandParameter([CommandParameterAst] $commandParameterAst)
    {
        $newArgument = $this.VisitElement($commandParameterAst.Argument)
        return [CommandParameterAst]::new($commandParameterAst.Extent, $commandParameterAst.ParameterName, $newArgument, $commandParameterAst.ErrorPosition)
    }

    [system.object] VisitFileRedirection([FileRedirectionAst] $fileRedirectionAst)
    {
        $newFile = $this.VisitElement($fileRedirectionAst.Location)
        return [FileRedirectionAst]::new($fileRedirectionAst.Extent, $fileRedirectionAst.FromStream, $newFile, $fileRedirectionAst.Append)
    }

    [system.object] VisitMergingRedirection([MergingRedirectionAst] $mergingRedirectionAst)
    {
        return [MergingRedirectionAst]::new($mergingRedirectionAst.Extent, $mergingRedirectionAst.FromStream, $mergingRedirectionAst.ToStream)
    }

    [system.object] VisitBinaryExpression([BinaryExpressionAst] $binaryExpressionAst)
    {
        $newLeft = $this.VisitElement($binaryExpressionAst.Left)
        $newRight = $this.VisitElement($binaryExpressionAst.Right)
        return [BinaryExpressionAst]::new($binaryExpressionAst.Extent, $newLeft, $binaryExpressionAst.Operator, $newRight, $binaryExpressionAst.ErrorPosition)
    }

    [system.object] VisitUnaryExpression([UnaryExpressionAst] $unaryExpressionAst)
    {
        $newChild = $this.VisitElement($unaryExpressionAst.Child)
        return [UnaryExpressionAst]::new($unaryExpressionAst.Extent, $unaryExpressionAst.TokenKind, $newChild)
    }

    [system.object] VisitConvertExpression([ConvertExpressionAst] $convertExpressionAst)
    {
        $newChild = $this.VisitElement($convertExpressionAst.Child)
        $newTypeConstraint = $this.VisitElement($convertExpressionAst.Type)
        return [ConvertExpressionAst]::new($convertExpressionAst.Extent, $newTypeConstraint, $newChild)
    }

    [system.object] VisitTypeExpression([TypeExpressionAst] $typeExpressionAst)
    {
        return [TypeExpressionAst]::new($typeExpressionAst.Extent, $typeExpressionAst.TypeName)
    }

    [system.object] VisitConstantExpression([ConstantExpressionAst] $constantExpressionAst)
    {
        return [ConstantExpressionAst]::new($constantExpressionAst.Extent, $constantExpressionAst.Value)
    }

    [system.object] VisitStringConstantExpression([StringConstantExpressionAst] $stringConstantExpressionAst)
    {
        $newVal = &{if ($stringConstantExpressionAst.Value -eq 'Cyan') {'Blue'} else {$stringConstantExpressionAst.Value}}
        return [StringConstantExpressionAst]::new($stringConstantExpressionAst.Extent, $newVal, $stringConstantExpressionAst.StringConstantType)
    }

    [system.object] VisitSubExpression([SubExpressionAst] $subExpressionAst)
    {
        $newStatementBlock = $this.VisitElement($subExpressionAst.SubExpression)
        return [SubExpressionAst]::new($subExpressionAst.Extent, $newStatementBlock)
    }

    [system.object] VisitUsingExpression([UsingExpressionAst] $usingExpressionAst)
    {
        $newUsingExpr = $this.VisitElement($usingExpressionAst.SubExpression)
        return [UsingExpressionAst]::new($usingExpressionAst.Extent, $newUsingExpr)
    }

    [system.object] VisitVariableExpression([VariableExpressionAst] $variableExpressionAst)
    {
        return [VariableExpressionAst]::new($variableExpressionAst.Extent, $variableExpressionAst.VariablePath.UserPath, $variableExpressionAst.Splatted)
    }

    [system.object] VisitMemberExpression([MemberExpressionAst] $memberExpressionAst)
    {
        $newExpr = $this.VisitElement($memberExpressionAst.Expression)
        $newMember = $this.VisitElement($memberExpressionAst.Member)
        return [MemberExpressionAst]::new($memberExpressionAst.Extent, $newExpr, $newMember, $memberExpressionAst.Static)
    }

    [system.object] VisitInvokeMemberExpression([InvokeMemberExpressionAst] $invokeMemberExpressionAst)
    {
        $newExpression = $this.VisitElement($invokeMemberExpressionAst.Expression)
        $newMethod = $this.VisitElement($invokeMemberExpressionAst.Member)
        $newArguments = $this.VisitElements($invokeMemberExpressionAst.Arguments)
        return [InvokeMemberExpressionAst]::new($invokeMemberExpressionAst.Extent, $newExpression, $newMethod, $newArguments, $invokeMemberExpressionAst.Static)
    }

    [system.object] VisitArrayExpression([ArrayExpressionAst] $arrayExpressionAst)
    {
        $newStatementBlock = $this.VisitElement($arrayExpressionAst.SubExpression)
        return [ArrayExpressionAst]::new($arrayExpressionAst.Extent, $newStatementBlock)
    }

    [system.object] VisitArrayLiteral([ArrayLiteralAst] $arrayLiteralAst)
    {
        $newArrayElements = $this.VisitElements($arrayLiteralAst.Elements)
        return [ArrayLiteralAst]::new($arrayLiteralAst.Extent, $newArrayElements)
    }

    [system.object] VisitHashtable([HashtableAst] $hashtableAst)
    {
        $newKeyValuePairs = [System.Collections.Generic.List[System.Tuple[ExpressionAst,StatementAst]]]::new()
        foreach ($keyValuePair in $hashtableAst.KeyValuePairs)
        {
            $newKey = $this.VisitElement($keyValuePair.Item1);
            $newValue = $this.VisitElement($keyValuePair.Item2);
            $newKeyValuePairs.Add([System.Tuple[ExpressionAst,StatementAst]]::new($newKey, $newValue)) # TODO NOT SURE
        }
        return [HashtableAst]::new($hashtableAst.Extent, $newKeyValuePairs)
    }

    [system.object] VisitScriptBlockExpression([ScriptBlockExpressionAst] $scriptBlockExpressionAst)
    {
        $newScriptBlock = $this.VisitElement($scriptBlockExpressionAst.ScriptBlock)
        return [ScriptBlockExpressionAst]::new($scriptBlockExpressionAst.Extent, $newScriptBlock)
    }

    [system.object] VisitParenExpression([ParenExpressionAst] $parenExpressionAst)
    {
        $newPipeline = $this.VisitElement($parenExpressionAst.Pipeline)
        return [ParenExpressionAst]::new($parenExpressionAst.Extent, $newPipeline)
    }

    [system.object] VisitExpandableStringExpression([ExpandableStringExpressionAst] $expandableStringExpressionAst)
    {
        return [ExpandableStringExpressionAst]::new($expandableStringExpressionAst.Extent,$expandableStringExpressionAst.Value,$expandableStringExpressionAst.StringConstantType)
    }

    [system.object] VisitIndexExpression([IndexExpressionAst] $indexExpressionAst)
    {
        $newTargetExpression = $this.VisitElement($indexExpressionAst.Target)
        $newIndexExpression = $this.VisitElement($indexExpressionAst.Index)
        return [IndexExpressionAst]::new($indexExpressionAst.Extent, $newTargetExpression, $newIndexExpression)
    }

    [system.object] VisitAttributedExpression([AttributedExpressionAst] $attributedExpressionAst)
    {
        $newAttribute = $this.VisitElement($attributedExpressionAst.Attribute)
        $newChild = $this.VisitElement($attributedExpressionAst.Child)
        return [AttributedExpressionAst]::new($attributedExpressionAst.Extent, $newAttribute, $newChild)
    }

    [system.object] VisitBlockStatement([BlockStatementAst] $blockStatementAst)
    {
        $newBody = $this.VisitElement($blockStatementAst.Body)
        return [BlockStatementAst]::new($blockStatementAst.Extent, $blockStatementAst.Kind, $newBody)
    }
}
#endregion

#region Invoke-PSProfiler
Function Measure-ScriptExecution {
    [cmdletbinding(DefaultParameterSetName="ScriptBlock")]
    param(
        [parameter(Mandatory=$true,ParameterSetName="ScriptBlock")]
        [scriptblock]$ScriptBlock,
        [parameter(Mandatory=$true,ParameterSetName="Path")]
        [string]$Path,
        [parameter(Mandatory=$false,ParameterSetName="__AllParametersets")]
        [string]$ExecutionResultVariable,
        [parameter(Mandatory=$false,ParameterSetName="__AllParametersets")]
        [hashtable]$Arguments,
        [parameter(Mandatory=$false,ParameterSetName="__AllParametersets")]
        [string]$VariableScope="1"
    )
    if($PSBoundParameters.Keys -icontains "Path") {
        if(-not (Test-Path $path)) {       
            throw "No such file"
        }
        $ScriptText = Get-Content $path -Raw 
        $ScriptBlock = [scriptblock]::Create($ScriptText)
    }
    $ScriptBlock = [scriptblock]::Create($ScriptBlock.ToString())
    $profiler = [Profiler]::new($ScriptBlock.Ast.Extent)
    $visitor  = [AstVisitor]::new($profiler)
    $newAst   = $ScriptBlock.Ast.Visit($visitor)
    # $executionResult = . $newAst.GetScriptBlock() @Arguments
    . $newAst.GetScriptBlock() @Arguments

    # [string[]]$lines = $ScriptBlock.ToString().Split("`n").TrimEnd()
    # for($i = 0; $i -lt $lines.Count;$i++){
    #     [pscustomobject]@{
    #         LineNo = $i+1 
    #         ExecutionTime = $profiler.StopWatches[$i].Elapsed
    #         Line = $lines[$i]
    #     }
    # }
    # if($ExecutionResultVariable) {
    #     Set-Variable -Name $ExecutionResultVariable -Value $executionResult -Scope $VariableScope
    # }
}


$ScriptBlock={
    $original = "User1","User2","User3","User4"
    $changed = "User3","User4","user5","User6"
    $added = Compare-Object $original $changed | 
        Where-Object SideIndicator -EQ "=>" | 
            Select-Object -ExpandProperty InputObject 
    $removed = Compare-Object $original $changed | 
        Where-Object SideIndicator -EQ "<=" | 
            Select-Object -ExpandProperty InputObject
    "##### added:"
    $added
    "##### removed:"
    &{
      Write-Host $removed -ForegroundColor Cyan
      Write-Host $removed -ForegroundColor Green
    } 6>&1 | &{param([Parameter(ValueFromPipeline)]$obj) 
      Get-PSCallStack | % InvocationInfo | % Line
      $PSCmdlet
      $ExecutionContext
      Write-Host $obj -ForegroundColor Yellow
    }
}
Measure-ScriptExecution -ScriptBlock $ScriptBlock
# Measure-ScriptExecution -ScriptBlock {"qu-qu" | Write-Host -ForegroundColor Cyan} 
# Measure-ScriptExecution -ScriptBlock $ScriptBlock 
