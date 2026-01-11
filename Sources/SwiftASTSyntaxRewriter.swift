//
//  SwiftASTSyntaxRewriter.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/12/12.
//
import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

class SwiftASTSyntaxRewriter: SyntaxRewriter {
    private let projectPath: String
    
    init(projectPath: String) {
        self.projectPath = projectPath
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        var newNode = node
        
        var importDeclSyntaxList: [CodeBlockItemSyntax] = [CodeBlockItemSyntax]()
        var otherDeclSyntaxList: [CodeBlockItemSyntax] = [CodeBlockItemSyntax]()
        node.statements.forEach { cbItemSyntax in
            if let _ = cbItemSyntax.item.as(ImportDeclSyntax.self) {
                importDeclSyntaxList.append(cbItemSyntax)
            } else {
                otherDeclSyntaxList.append(cbItemSyntax)
            }
        }
        
        importDeclSyntaxList.shuffle()
        otherDeclSyntaxList.shuffle()
        
        var reorderedSyntaxList: [CodeBlockItemSyntax] = [CodeBlockItemSyntax]()
        reorderedSyntaxList.append(contentsOf: importDeclSyntaxList)
        reorderedSyntaxList.append(contentsOf: otherDeclSyntaxList)
        
        newNode = node.with(\.statements, CodeBlockItemListSyntax(reorderedSyntaxList).with(\.leadingTrivia, node.statements.leadingTrivia).with(\.trailingTrivia, node.statements.trailingTrivia)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        
        let updatedBindings: [PatternBindingSyntax] = node.bindings.map { bindings in
            guard let identifierPattern: IdentifierPatternSyntax = bindings.pattern.as(IdentifierPatternSyntax.self) else {
                return bindings
            }
            
            let idName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: identifierPattern.identifier.text)
            var typeAnnotationSyntax: TypeAnnotationSyntax?
            
            if let typeAnnSyntax: TypeAnnotationSyntax = bindings.typeAnnotation?.as(TypeAnnotationSyntax.self),
                      let typeIDSyntax: IdentifierTypeSyntax = typeAnnSyntax.type.as(IdentifierTypeSyntax.self) {
                let typeName = SwiftConfuseHelper.confusedSymbolName(symbolName: typeIDSyntax.name.text)
                typeAnnotationSyntax = typeAnnSyntax.with(\.type, TypeSyntax(stringLiteral: typeName).with(\.leadingTrivia, typeIDSyntax.leadingTrivia).with(\.trailingTrivia, typeIDSyntax.trailingTrivia)).with(\.leadingTrivia, typeAnnSyntax.leadingTrivia).with(\.trailingTrivia, typeAnnSyntax.trailingTrivia)
            }
            
            let syntaxPattern = PatternSyntax(stringLiteral: idName).with(\.leadingTrivia, identifierPattern.leadingTrivia).with(\.trailingTrivia, identifierPattern.trailingTrivia)
            var newBindings = bindings.with(\.leadingTrivia, bindings.leadingTrivia).with(\.pattern, syntaxPattern).with(\.trailingTrivia, bindings.trailingTrivia)
            
            if let typeAnnotationSyntax {
                newBindings = newBindings.with(\.typeAnnotation, typeAnnotationSyntax)
            }
            
            return newBindings
        }
        
        let newNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.bindings, PatternBindingListSyntax(updatedBindings)).with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let confusedName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: node.name.text)
        
        var newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedName).with(\.leadingTrivia, node.name.leadingTrivia).with(\.trailingTrivia, node.name.trailingTrivia))
        
        var confusedInheritedList: InheritedTypeListSyntax = InheritedTypeListSyntax()
        if let inheritedList = node.inheritanceClause {
            let inheritedCount = inheritedList.inheritedTypes.count
            for (inheritedIndex, inheritedType) in inheritedList.inheritedTypes.enumerated() {
                let confusedSymbolName = SwiftConfuseHelper.confusedSymbolName(symbolName: inheritedType.type.trimmedDescription)
                
                var confusedInheritedType: InheritedTypeSyntax = InheritedTypeSyntax(type: TypeSyntax(stringLiteral: confusedSymbolName).with(\.leadingTrivia, inheritedType.type.leadingTrivia).with(\.trailingTrivia, inheritedType.type.trailingTrivia)).with(\.leadingTrivia, inheritedType.leadingTrivia).with(\.trailingTrivia, inheritedType.trailingTrivia)
                if inheritedIndex != inheritedCount - 1 {
                    confusedInheritedType = confusedInheritedType.with(\.trailingComma, .commaToken())
                }
                
                confusedInheritedList.append(confusedInheritedType)
            }
            
            newNode = newNode.with(\.inheritanceClause, InheritanceClauseSyntax(leadingTrivia: node.inheritanceClause?.leadingTrivia, inheritedTypes: confusedInheritedList, trailingTrivia: node.inheritanceClause?.trailingTrivia))
        }
        
        let members = newNode.memberBlock.members.shuffled()
        newNode = newNode.with(\.memberBlock, newNode.memberBlock.with(\.members, MemberBlockItemListSyntax(members).with(\.leadingTrivia, newNode.memberBlock.members.leadingTrivia).with(\.trailingTrivia, newNode.memberBlock.members.trailingTrivia))).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        SwiftSourceScopeManager.shared.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        guard let extendedType = node.extendedType.as(IdentifierTypeSyntax.self) else {
            return super.visit(node)
        }
        
        let confusedName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: extendedType.name.text)
        
        let newExtendedType = IdentifierTypeSyntax(
            name: TokenSyntax.identifier(confusedName),
            genericArgumentClause: extendedType.genericArgumentClause
        ).with(\.leadingTrivia, extendedType.leadingTrivia).with(\.trailingTrivia, extendedType.trailingTrivia)
        
        let newNode = node.with(\.extendedType, TypeSyntax(newExtendedType)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let confusedFuncName: String =
                SwiftConfuseHelper.confusedSymbolName(symbolName: node.name.text)
        
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedFuncName)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        SwiftSourceScopeManager.shared.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
        SwiftSourceScopeManager.shared.pushScope(false)
        var newNode = node
        
        let confusedConditions = node.conditions.map { condSyntax in
            if let optionalBindingCondSyntax = condSyntax.condition.as(OptionalBindingConditionSyntax.self) {
                if let identifierPatternSyntax = optionalBindingCondSyntax.pattern.as(IdentifierPatternSyntax.self) {
                    let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: identifierPatternSyntax.identifier.text)
                    let confusedIDPatternSyntax = identifierPatternSyntax.with(\.identifier, TokenSyntax(stringLiteral: confusedName)).with(\.leadingTrivia, identifierPatternSyntax.leadingTrivia).with(\.trailingTrivia, identifierPatternSyntax.trailingTrivia)
                    
                    let confusedOptBindSyntax = optionalBindingCondSyntax.with(\.pattern, PatternSyntax(confusedIDPatternSyntax)).with(\.leadingTrivia, optionalBindingCondSyntax.leadingTrivia).with(\.trailingTrivia, optionalBindingCondSyntax.trailingTrivia)
                    
                    return condSyntax.with(\.condition, ConditionElementSyntax.Condition(confusedOptBindSyntax)).with(\.leadingTrivia, condSyntax.leadingTrivia).with(\.trailingTrivia, condSyntax.trailingTrivia)
                }
            }
            
            return condSyntax
        }
        
        newNode = node.with(\.conditions, ConditionElementListSyntax(confusedConditions)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        return super.visit(newNode)
    }
    
    override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
        SwiftSourceScopeManager.shared.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: GenericArgumentClauseSyntax) -> GenericArgumentClauseSyntax {
        var newNode = node
        return super.visit(newNode)
    }
    
    override func visit(_ node: GenericArgumentSyntax) -> GenericArgumentSyntax {
        var newNode = node
        return super.visit(newNode)
    }
    
    override func visit(_ node: GenericParameterClauseSyntax) -> GenericParameterClauseSyntax {
        var newNode = node
        return super.visit(newNode)
    }
    
    override func visit(_ node: GenericParameterSyntax) -> GenericParameterSyntax {
        var newNode = node
        return super.visit(newNode)
    }
    
    override func visit(_ node: GenericWhereClauseSyntax) -> GenericWhereClauseSyntax {
        var newNode = node
        return super.visit(newNode)
    }

    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
        var newNode = node
        
        SwiftSourceScopeManager.shared.pushScope(false)
        let confusedConditions = node.conditions.map { condSyntax in
            if let optionalBindingCondSyntax = condSyntax.condition.as(OptionalBindingConditionSyntax.self) {
                if let identifierPatternSyntax = optionalBindingCondSyntax.pattern.as(IdentifierPatternSyntax.self) {
                    let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: identifierPatternSyntax.identifier.text)
                    let confusedIDPatternSyntax = identifierPatternSyntax.with(\.identifier, TokenSyntax(stringLiteral: confusedName)).with(\.leadingTrivia, identifierPatternSyntax.leadingTrivia).with(\.trailingTrivia, identifierPatternSyntax.trailingTrivia)
                    
                    let confusedOptBindSyntax = optionalBindingCondSyntax.with(\.pattern, PatternSyntax(confusedIDPatternSyntax)).with(\.leadingTrivia, optionalBindingCondSyntax.leadingTrivia).with(\.trailingTrivia, optionalBindingCondSyntax.trailingTrivia)
                    
                    return condSyntax.with(\.condition, ConditionElementSyntax.Condition(confusedOptBindSyntax)).with(\.leadingTrivia, condSyntax.leadingTrivia).with(\.trailingTrivia, condSyntax.trailingTrivia)
                }
            }
            
            return condSyntax
        }
        
        newNode = node.with(\.conditions, ConditionElementListSyntax(confusedConditions)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: TupleExprSyntax) -> ExprSyntax {
        var newNode = node
        return super.visit(newNode)
    }
    
    override func visit(_ node: SwitchCaseLabelSyntax) -> SwitchCaseLabelSyntax {
        var newNode = node
        return super.visit(newNode)
    }
    
    override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
        var newNode = node
        return super.visit(newNode)
    }
    
    override func visit(_ node: ReturnClauseSyntax) -> ReturnClauseSyntax {
        var newNode = node
        
        if let identifierSyntax: IdentifierTypeSyntax = node.type.as(IdentifierTypeSyntax.self) {
            let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: identifierSyntax.name.text)
            newNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia).with(\.type, TypeSyntax(stringLiteral: confusedName).with(\.leadingTrivia, identifierSyntax.leadingTrivia).with(\.trailingTrivia, identifierSyntax.trailingTrivia))
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
        var parentNode = node.parent
        while parentNode != nil && parentNode?.as(FunctionDeclSyntax.self) == nil {
            parentNode = parentNode?.parent
        }
        
        var newNode = node
        
        if let funcNode: FunctionDeclSyntax = parentNode?.as(FunctionDeclSyntax.self),
           let funcName: String = SwiftConfusedSymbolTable.shared.reversedSymbol[funcNode.name.text],
           SwiftConfuseHelper.shouldSymbolConfused(funcName) {
            
            let firstName = node.firstName.text
            let confusedFirstName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: firstName, bAlwaysConfuse: true)
            
            newNode = newNode.with(\.firstName, TokenSyntax(stringLiteral: confusedFirstName).with(\.leadingTrivia, node.firstName.leadingTrivia).with(\.trailingTrivia, node.firstName.trailingTrivia))
        }
        
        if let secondName = newNode.secondName?.text {
            let confusedSecondName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: secondName, bAlwaysConfuse: true)
            
            var tokenSyntax = TokenSyntax(stringLiteral: confusedSecondName)
            if let leadingTrivia = node.secondName?.leadingTrivia {
                tokenSyntax = tokenSyntax.with(\.leadingTrivia, leadingTrivia)
            }
            if let trailingTrivia = node.secondName?.trailingTrivia {
                tokenSyntax = tokenSyntax.with(\.trailingTrivia, trailingTrivia)
            }
            
            newNode = newNode.with(\.secondName, tokenSyntax)
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
        let baseName = node.baseName
        
        let confusedBaseName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: baseName.text)
        let newNode = node.with(\.baseName, TokenSyntax(stringLiteral: confusedBaseName).with(\.leadingTrivia, baseName.leadingTrivia).with(\.trailingTrivia, baseName.trailingTrivia))
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        var newNode = node
        
        var exprList: LabeledExprListSyntax = LabeledExprListSyntax()
        newNode.arguments.forEach { exprSyntax in
            var confusedExpr: LabeledExprSyntax = exprSyntax
            if let label = confusedExpr.label {
                let confusedLabelText = SwiftConfuseHelper.confusedSymbolName(symbolName: label.text)
                confusedExpr = confusedExpr.with(\.label, TokenSyntax(stringLiteral: confusedLabelText)).with(\.leadingTrivia, confusedExpr.leadingTrivia).with(\.trailingTrivia, confusedExpr.trailingTrivia)
            }
            
            exprList.append(confusedExpr)
        }
        
        newNode = newNode.with(\.arguments, exprList)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        
        let confusedName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: node.name.text)
        
        var newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedName).with(\.leadingTrivia, node.name.leadingTrivia).with(\.trailingTrivia, node.name.trailingTrivia))
        
        var confusedInheritedList: InheritedTypeListSyntax = InheritedTypeListSyntax()
        if let inheritedList = node.inheritanceClause {
            let inheritedCount = inheritedList.inheritedTypes.count
            for (inheritedIndex, inheritedType) in inheritedList.inheritedTypes.enumerated() {
                let confusedSymbolName = SwiftConfuseHelper.confusedSymbolName(symbolName: inheritedType.type.description)
                
                var confusedInheritedType: InheritedTypeSyntax = InheritedTypeSyntax(type: TypeSyntax(stringLiteral: confusedSymbolName).with(\.leadingTrivia, inheritedType.type.leadingTrivia).with(\.trailingTrivia, inheritedType.type.trailingTrivia)).with(\.leadingTrivia, inheritedType.leadingTrivia).with(\.trailingTrivia, inheritedType.trailingTrivia)
                if inheritedIndex != inheritedCount - 1 {
                    confusedInheritedType = confusedInheritedType.with(\.trailingComma, .commaToken())
                }
                
                confusedInheritedList.append(confusedInheritedType)
            }
            
            newNode = newNode.with(\.inheritanceClause, InheritanceClauseSyntax(leadingTrivia: node.inheritanceClause?.leadingTrivia, inheritedTypes: confusedInheritedList, trailingTrivia: node.inheritanceClause?.trailingTrivia))
        }
        
        newNode = newNode.with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        SwiftSourceScopeManager.shared.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        SwiftSourceScopeManager.shared.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureCaptureSyntax) -> ClosureCaptureSyntax {

        let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: node.name.text)
        
        let newNode = node.with(\.leadingTrivia, node.leadingTrivia)
            .with(\.name, TokenSyntax(stringLiteral: confusedName)
                .with(\.leadingTrivia, node.name.leadingTrivia)
                .with(\.leadingTrivia, node.name.leadingTrivia))
            .with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        SwiftSourceScopeManager.shared.pushScope(false)
        
        var newNode = node
        
        if let identifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self) {
            let confusedIdentifier = SwiftConfuseHelper.confusedSymbolName(symbolName: identifierPatternSyntax.identifier.text)
            let pattern = identifierPatternSyntax.with(\.identifier, TokenSyntax(stringLiteral: confusedIdentifier).with(\.leadingTrivia, identifierPatternSyntax.identifier.leadingTrivia).with(\.trailingTrivia, identifierPatternSyntax.identifier.trailingTrivia))
            
            newNode = node.with(\.pattern, PatternSyntax(pattern).with(\.leadingTrivia, identifierPatternSyntax.leadingTrivia).with(\.trailingTrivia, identifierPatternSyntax.trailingTrivia)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        var newNode = node
        
        SwiftSourceScopeManager.shared.pushScope(false)
        let confusedConditions = node.conditions.map { condSyntax in
            if let optionalBindingCondSyntax = condSyntax.condition.as(OptionalBindingConditionSyntax.self) {
                if let identifierPatternSyntax = optionalBindingCondSyntax.pattern.as(IdentifierPatternSyntax.self) {
                    let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: identifierPatternSyntax.identifier.text)
                    let confusedIDPatternSyntax = identifierPatternSyntax.with(\.identifier, TokenSyntax(stringLiteral: confusedName)).with(\.leadingTrivia, identifierPatternSyntax.leadingTrivia).with(\.trailingTrivia, identifierPatternSyntax.trailingTrivia)
                    
                    let confusedOptBindSyntax = optionalBindingCondSyntax.with(\.pattern, PatternSyntax(confusedIDPatternSyntax)).with(\.leadingTrivia, optionalBindingCondSyntax.leadingTrivia).with(\.trailingTrivia, optionalBindingCondSyntax.trailingTrivia)
                    
                    return condSyntax.with(\.condition, ConditionElementSyntax.Condition(confusedOptBindSyntax)).with(\.leadingTrivia, condSyntax.leadingTrivia).with(\.trailingTrivia, condSyntax.trailingTrivia)
                }
            }
            
            return condSyntax
        }
        
        newNode = node.with(\.conditions, ConditionElementListSyntax(confusedConditions)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
        var newNode = node
        
        let confusedParameters = node.parameters.map { parameter in
            var firstNameToken = parameter.firstName
            if firstNameToken != nil {
                let confusedFirstName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: firstNameToken!.text)
                firstNameToken = TokenSyntax(stringLiteral: confusedFirstName).with(\.leadingTrivia, firstNameToken!.leadingTrivia).with(\.trailingTrivia, firstNameToken!.trailingTrivia)
            }
            
            var secondNameToken = parameter.secondName
            if secondNameToken != nil {
                let confusedSecondName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: secondNameToken!.text, bAlwaysConfuse: true)
                secondNameToken = TokenSyntax(stringLiteral: confusedSecondName).with(\.leadingTrivia, secondNameToken!.leadingTrivia).with(\.trailingTrivia, secondNameToken!.trailingTrivia)
            }
            
            return parameter.with(\.firstName, firstNameToken).with(\.secondName, secondNameToken).with(\.leadingTrivia, parameter.leadingTrivia).with(\.trailingTrivia, parameter.trailingTrivia)
        }
        
        newNode = node.with(\.parameters, TupleTypeElementListSyntax(confusedParameters)).with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {

        let confusedName: String = SwiftConfuseHelper.confusedSymbolName(symbolName: node.name.text)
        
        var newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedName).with(\.leadingTrivia, node.name.leadingTrivia).with(\.trailingTrivia, node.name.trailingTrivia))
        
        var confusedInheritedList: InheritedTypeListSyntax = InheritedTypeListSyntax()
        if let inheritedList = node.inheritanceClause {
            let inheritedCount = inheritedList.inheritedTypes.count
            for (inheritedIndex, inheritedType) in inheritedList.inheritedTypes.enumerated() {
                let confusedSymbolName = SwiftConfuseHelper.confusedSymbolName(symbolName: inheritedType.type.trimmedDescription)
                
                var confusedInheritedType: InheritedTypeSyntax = InheritedTypeSyntax(type: TypeSyntax(stringLiteral: confusedSymbolName).with(\.leadingTrivia, inheritedType.type.leadingTrivia).with(\.trailingTrivia, inheritedType.type.trailingTrivia)).with(\.leadingTrivia, inheritedType.leadingTrivia).with(\.trailingTrivia, inheritedType.trailingTrivia)
                if inheritedIndex != inheritedCount - 1 {
                    confusedInheritedType = confusedInheritedType.with(\.trailingComma, .commaToken())
                }
                
                confusedInheritedList.append(confusedInheritedType)
            }
            
            newNode = newNode.with(\.inheritanceClause, InheritanceClauseSyntax(leadingTrivia: node.inheritanceClause?.leadingTrivia, inheritedTypes: confusedInheritedList, trailingTrivia: node.inheritanceClause?.trailingTrivia))
        }
        
        newNode = newNode.with(\.leadingTrivia, node.leadingTrivia).with(\.trailingTrivia, node.trailingTrivia)
        
        SwiftSourceScopeManager.shared.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        
        let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: node.name.text)
        
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
        .with(\.leadingTrivia, node.leadingTrivia)
        .with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        let confusedElements = node.elements.map { enumCaseElement in
            let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: enumCaseElement.name.text)
            
            return enumCaseElement.with(\.name, TokenSyntax(stringLiteral: confusedName)
                .with(\.leadingTrivia, enumCaseElement.leadingTrivia)
                .with(\.trailingTrivia, enumCaseElement.trailingTrivia))
        }
        
        newNode = node.with(\.elements, EnumCaseElementListSyntax(confusedElements)
            .with(\.leadingTrivia, node.elements.leadingTrivia)
            .with(\.trailingTrivia, node.elements.trailingTrivia))
        .with(\.leadingTrivia, node.leadingTrivia)
        .with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
        switch node.parameterClause {
        case .parameterClause(let paramClause):
            let newParams = paramClause.parameters.map { param -> ClosureParameterSyntax in
                var modifiedParam = param
                
                if let secondName = param.secondName {
                    let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: secondName.text)
                    
                    modifiedParam = modifiedParam.with(
                        \.secondName,
                         secondName.with(\.tokenKind, .identifier(confusedName))
                    )
                }
                
                let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: param.firstName.text)
                modifiedParam = modifiedParam.with(\.firstName, param.firstName.with(\.tokenKind, .identifier(confusedName)))
                
                return modifiedParam
            }
            
            let newParamList = ClosureParameterListSyntax(newParams)
            
            let newParamClause = paramClause.with(\.parameters, newParamList)
            
            let modifiedNode = node.with(\.parameterClause, .parameterClause(newParamClause))
            return super.visit(modifiedNode)
            
        case .simpleInput(let paramList):
            
            let newParams = paramList.map { param -> ClosureShorthandParameterSyntax in
                let confusedName = SwiftConfuseHelper.confusedSymbolName(symbolName: param.name.text)
                
                return param.with(
                    \.name,
                     param.name.with(\.tokenKind, .identifier(confusedName))
                )
            }
            
            let newParamList = ClosureShorthandParameterListSyntax(newParams)
            let modifiedNode = node.with(\.parameterClause, .simpleInput(newParamList))
            return super.visit(modifiedNode)
            
        case .none:
            return super.visit(node)
        }
    }
    
    override func visitPost(_ node: Syntax) {
        if node.as(ClassDeclSyntax.self) != nil {
            SwiftSourceScopeManager.shared.popScope(true)
        } else if node.as(FunctionDeclSyntax.self) != nil {
            SwiftSourceScopeManager.shared.popScope(true)
        } else if node.as(ProtocolDeclSyntax.self) != nil {
            SwiftSourceScopeManager.shared.popScope(true)
        } else if node.as(ForStmtSyntax.self) != nil {
            SwiftSourceScopeManager.shared.popScope(true)
        } else if node.as(IfExprSyntax.self) != nil {
            SwiftSourceScopeManager.shared.popScope(true)
        } else if node.as(WhileStmtSyntax.self) != nil {
            SwiftSourceScopeManager.shared.popScope(true)
        } else if node.as(GuardStmtSyntax.self) != nil {
            SwiftSourceScopeManager.shared.popScope(true)
        } else if node.as(DoStmtSyntax.self) != nil {
            SwiftSourceScopeManager.shared.popScope(true)
        } else if node.as(ClosureExprSyntax.self) != nil {
            SwiftSourceScopeManager.shared.popScope(true)
        }
    }
}
