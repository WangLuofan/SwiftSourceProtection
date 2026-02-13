//
//  SwiftASTSyntaxRewriter.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/2/6.
//

import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

class SwiftASTSyntaxRewriter: SyntaxRewriter {
    private let projectPath: String
    private let sourceFile: String
    
    init(projectPath: String, sourceFile: String) {
        self.projectPath = projectPath
        self.sourceFile = sourceFile
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let clsName: String = node.name.text
        
        guard let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsName) as? SwiftSourceClassSymbol,
              let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol) else {
            return super.visit(node)
        }
        
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        parentStack.append(clsSymbol)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        let clsName: String = node.name.text
        
        guard let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsName) as? SwiftSourceClassSymbol,
              let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol) else {
            return super.visit(node)
        }
        
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        parentStack.append(clsSymbol)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
        
        var newNode = node
        let refName: String = node.baseName.text
        
        if let refSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(refName) {
            newNode = node.with(\.baseName, TokenSyntax(stringLiteral: refSymbol.confusedSymbol ?? refSymbol.originalSymbol)
                .with(\.leadingTrivia, node.baseName.leadingTrivia)
                .with(\.trailingTrivia, node.baseName.trailingTrivia)
            )
        }
        
        return super.visit(newNode)
    }
    
//    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
//        guard let extendedType = node.extendedType.as(IdentifierTypeSyntax.self),
//              let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(extendedType.name.text) as? SwiftSourceClassSymbol,
//              let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol) else {
//            return super.visit(node)
//        }
//        
//        let newNode = node.with(\.extendedType,
//                                 TypeSyntax(IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: confusedSymbolName)))
//            .with(\.leadingTrivia, node.extendedType.leadingTrivia)
//            .with(\.trailingTrivia, node.extendedType.trailingTrivia))
//            .with(\.leadingTrivia, node.leadingTrivia)
//            .with(\.trailingTrivia, node.trailingTrivia)
//        
//        return super.visit(newNode)
//    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        var funcSymbol: SwiftSourceFunctionSymbol? = nil
        if node.isLocalDecl {
            funcSymbol = node.functionSymbol(self.sourceFile)
            SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(funcSymbol!)
        }
        
        if funcSymbol == nil {
            funcSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(node.name.text) as? SwiftSourceFunctionSymbol
        }
        
        if let funcSymbol,
           let confusedFuncSymbol: String = SwiftConfusedHelper.confusedSymbol(funcSymbol) {
            newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedFuncSymbol)
                .with(\.leadingTrivia, node.name.leadingTrivia)
                .with(\.trailingTrivia, node.name.trailingTrivia))
        }
        
        SwiftSourceScopeManager.sharedManager.pushScope()
        if let funcSymbol {
            parentStack.append(funcSymbol)
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
        var newNode = node
        
        if let funcSymbol: SwiftSourceFunctionSymbol = parentStack.last as? SwiftSourceFunctionSymbol {
            if let secondName = node.secondName {
                let paramSymbol: SwiftSourceSymbol = node.funcParameterSymbol(self.sourceFile)
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(paramSymbol)
                
                if let confusedSecondName: String = SwiftConfusedHelper.confusedSymbol(paramSymbol) {
                    newNode = node.with(\.secondName, TokenSyntax(stringLiteral: confusedSecondName)
                        .with(\.leadingTrivia, secondName.leadingTrivia)
                        .with(\.trailingTrivia, secondName.trailingTrivia))
                }
            }
            
            if let firstSymbol: SwiftSourceSymbol = funcSymbol.labels[node.firstName.text] {
                if let confusedLabelSymbolName: String = firstSymbol.confusedSymbol {
                    newNode = newNode.with(\.firstName, TokenSyntax(stringLiteral: confusedLabelSymbolName)
                        .with(\.leadingTrivia, node.firstName.leadingTrivia)
                        .with(\.leadingTrivia, node.firstName.leadingTrivia)
                        .with(\.trailingTrivia, node.firstName.trailingTrivia))
                }
                
                if node.secondName == nil {
                    SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(firstSymbol)
                }
            }
        }
        
        
        if let typeAnnon: IdentifierTypeSyntax = node.type.as(IdentifierTypeSyntax.self),
           let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(typeAnnon.name.text),
           let confusedTypeName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol) {
            
            newNode = newNode.with(\.type, TypeSyntax(IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: confusedTypeName)))
                .with(\.leadingTrivia, node.type.leadingTrivia)
                .with(\.trailingTrivia, node.type.trailingTrivia))
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        var newNode = node
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        var confusedConds: [ConditionElementSyntax] = [ConditionElementSyntax]()
        node.conditions.forEach { condElemSyntax in
            if let optBindCondSyntax: OptionalBindingConditionSyntax = condElemSyntax.condition.as(OptionalBindingConditionSyntax.self),
               let idPattern: IdentifierPatternSyntax = optBindCondSyntax.pattern.as(IdentifierPatternSyntax.self) {
                
                let varSymbol: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
                varSymbol.originalSymbol = idPattern.identifier.text
                let confusedSymbol = SwiftConfusedHelper.confusedSymbol(varSymbol)
                
                var confusedCondition = optBindCondSyntax.with(\.pattern, PatternSyntax(idPattern.with(\.identifier, TokenSyntax(stringLiteral: confusedSymbol ?? idPattern.identifier.text))))
                
                if let typeAnnotation = optBindCondSyntax.typeAnnotation,
                   let idType: IdentifierTypeSyntax = typeAnnotation.type.as(IdentifierTypeSyntax.self) {
                    varSymbol.symbolType = idType.name.text
                    
                    if let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(idType.name.text),
                       let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol) {
                        confusedCondition = confusedCondition.with(
                            \.typeAnnotation, optBindCondSyntax.typeAnnotation?
                                .with(\.type, TypeSyntax(IdentifierTypeSyntax(
                                    leadingTrivia: idType.leadingTrivia,
                                    name: TokenSyntax(stringLiteral: confusedSymbolName),
                                    trailingTrivia: idType.trailingTrivia)
                                ))
                        )
                    }
                }
                
                confusedConds.append(condElemSyntax.with(\.condition, ConditionElementSyntax.Condition(confusedCondition)))
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(varSymbol)
            }
        }
        
        newNode = node.with(\.conditions, ConditionElementListSyntax(confusedConds))
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        var newNode = node
        let enumTokenStr: String = node.name.text
        
        if let enumSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(enumTokenStr) as? SwiftSourceClassSymbol,
           let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(enumSymbol) {
            newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName))
            
            parentStack.append(enumSymbol)
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        if let enumSymbol: SwiftSourceClassSymbol = parentStack.last as? SwiftSourceClassSymbol {
            var newElements: [EnumCaseElementSyntax] = [EnumCaseElementSyntax]()
            node.elements.forEach { enumCaseElemSyntax in
                var enumCaseSymbol: SwiftSourceEnumCaseSymbol?
                for child in enumSymbol.children {
                    if child.originalSymbol == enumCaseElemSyntax.name.text {
                        enumCaseSymbol = child as? SwiftSourceEnumCaseSymbol
                        break
                    }
                }
                
                if let enumCaseSymbol,
                   let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(enumCaseSymbol) {
                    var element = enumCaseElemSyntax
                        .with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
                            .with(\.leadingTrivia, enumCaseElemSyntax.name.leadingTrivia)
                            .with(\.trailingTrivia, enumCaseElemSyntax.name.trailingTrivia))
                        .with(\.leadingTrivia, enumCaseElemSyntax.leadingTrivia)
                        .with(\.trailingTrivia, enumCaseElemSyntax.trailingTrivia)

                    if let parameterClause: EnumCaseParameterClauseSyntax = enumCaseElemSyntax.parameterClause {
                        var confusedParameters: [EnumCaseParameterSyntax] = [EnumCaseParameterSyntax]()
                        parameterClause.parameters.forEach { paramElemSyntax in
                            if let typeIdent: IdentifierTypeSyntax = paramElemSyntax.type.as(IdentifierTypeSyntax.self),
                               let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(typeIdent.name.text),
                               let confusedTypeSymbolName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol) {
                                let confusedParam = EnumCaseParameterSyntax(stringLiteral: confusedTypeSymbolName)
                                    .with(\.leadingTrivia, paramElemSyntax.leadingTrivia)
                                    .with(\.trailingTrivia, paramElemSyntax.trailingTrivia)
                                confusedParameters.append(confusedParam)
                            }
                        }
                        
                        element = element.with(\.parameterClause, parameterClause.with(\.parameters, EnumCaseParameterListSyntax(confusedParameters)))
                    }
                    
                    newElements.append(element)
                }
            }
            
            newNode = node.with(\.elements, EnumCaseElementListSyntax(newElements)
                .with(\.leadingTrivia, node.elements.leadingTrivia)
                .with(\.trailingTrivia, node.elements.trailingTrivia))
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        /// 如果是局部变量，先收集信息，添加作用域，再进行混淆
        if node.isLocalDecl {
            let localSymbol: SwiftSourceSymbol = node.variableSymbol(self.projectPath)
            SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(localSymbol)
        }
        
        var newBindings: [PatternBindingSyntax] = [PatternBindingSyntax]()
        node.bindings.forEach { binding in
            if let patternBinding: IdentifierPatternSyntax = binding.pattern.as(IdentifierPatternSyntax.self),
               let symbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(patternBinding.identifier.text),
               let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(symbol) {
                
                parentStack.append(symbol)
                
                let newPattern: IdentifierPatternSyntax = patternBinding.with(\.identifier, TokenSyntax(stringLiteral: confusedSymbolName)
                    .with(\.leadingTrivia, patternBinding.identifier.leadingTrivia)
                    .with(\.trailingTrivia, patternBinding.identifier.trailingTrivia))
                
                if let newPattern: PatternSyntax = PatternSyntax(newPattern) {
                    var newBinding = binding.with(\.pattern, newPattern)
                    
                    var confusedTypeAnnotation: TypeAnnotationSyntax?
                    if let typeAnnotation: TypeAnnotationSyntax = binding.typeAnnotation {
                        if let idTypeSyntax: IdentifierTypeSyntax = typeAnnotation.type.as(IdentifierTypeSyntax.self),
                           let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(idTypeSyntax.name.text),
                           let confusedTypeName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol) {
                            
                            confusedTypeAnnotation = typeAnnotation.with(\.type, TypeSyntax(
                                idTypeSyntax.with(\.name, TokenSyntax(stringLiteral: confusedTypeName)
                                    .with(\.leadingTrivia, idTypeSyntax.leadingTrivia)
                                    .with(\.trailingTrivia, idTypeSyntax.trailingTrivia)))
                            )
                            
                        } else if let optTypeAnnotation: OptionalTypeSyntax = typeAnnotation.type.as(OptionalTypeSyntax.self),
                                  let wrappedType = optTypeAnnotation.wrappedType.as(IdentifierTypeSyntax.self),
                                  let wrappedTypeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(wrappedType.name.text),
                                  let confusedTypeAnnotationName: String = SwiftConfusedHelper.confusedSymbol(wrappedTypeSymbol) {
                            
                            confusedTypeAnnotation = typeAnnotation.with(\.type, TypeSyntax(
                                optTypeAnnotation.with(
                                    \.wrappedType, TypeSyntax(wrappedType
                                        .with(\.name, TokenSyntax(stringLiteral: confusedTypeAnnotationName))
                                    )
                                ))
                            )
                        }
                        
                        if let confusedTypeAnnotation {
                            newBinding = newBinding.with(\.typeAnnotation, confusedTypeAnnotation)
                                .with(\.leadingTrivia, binding.leadingTrivia)
                                .with(\.trailingTrivia, binding.trailingTrivia)
                        }
                    }
                    
                    newBindings.append(newBinding)
                    return
                }
                
                newBindings.append(binding)
            }
        }
        
        newNode = node.with(\.bindings, PatternBindingListSyntax(newBindings)
            .with(\.leadingTrivia, node.bindings.leadingTrivia)
            .with(\.trailingTrivia, node.bindings.trailingTrivia))

        return super.visit(newNode)
    }
    
    override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
        var newNode = node
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        var confusedConditions: [ConditionElementSyntax] = [ConditionElementSyntax]()
        node.conditions.forEach { conditionElem in
            var newCondition: ConditionElementSyntax? = conditionElem
            
            if let condition: OptionalBindingConditionSyntax = conditionElem.condition.as(OptionalBindingConditionSyntax.self),
               let idPattern: IdentifierPatternSyntax = condition.pattern.as(IdentifierPatternSyntax.self) {
                let varSymbol: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
                
                varSymbol.originalSymbol = idPattern.identifier.text
                varSymbol.parent = parentStack.last
                
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(varSymbol)
                if let confusedSymbol = SwiftConfusedHelper.confusedSymbol(varSymbol) {
                    let optConfusedPattern: IdentifierPatternSyntax = idPattern.with(\.identifier, TokenSyntax(stringLiteral: confusedSymbol))
                    
                    var confusedTypeAnno = condition.typeAnnotation
                    if let typeAnnotation = condition.typeAnnotation,
                       let typeId: IdentifierTypeSyntax = typeAnnotation.type.as(IdentifierTypeSyntax.self) {
                        varSymbol.symbolType = typeId.name.text
                        if let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(typeId.name.text),
                           let confusedType: String = SwiftConfusedHelper.confusedSymbol(typeSymbol) {
                            confusedTypeAnno = typeAnnotation.with(
                                \.type, TypeSyntax(IdentifierTypeSyntax(
                                    leadingTrivia: typeId.leadingTrivia,
                                    name: TokenSyntax(
                                        stringLiteral: confusedType),
                                    trailingTrivia: typeId.trailingTrivia
                                ))
                            )
                        }
                    }
                    
                    var confusedCondition = condition.with(\.pattern, PatternSyntax(optConfusedPattern))
                    if let confusedTypeAnno {
                        confusedCondition = confusedCondition.with(\.typeAnnotation, confusedTypeAnno)
                    }
                    
                    newCondition = conditionElem.with(\.condition, ConditionElementSyntax.Condition(confusedCondition))
                }
            }
            
            if let newCondition {
                confusedConditions.append(newCondition)
            }
        }
        
        newNode = node.with(\.conditions, ConditionElementListSyntax(confusedConditions)
            .with(\.leadingTrivia, node.conditions.leadingTrivia)
            .with(\.trailingTrivia, node.conditions.trailingTrivia))
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
        var parent = node.parent
        
        while parent != nil {
            if let _: GuardStmtSyntax = parent?.as(GuardStmtSyntax.self) {
                SwiftSourceScopeManager.sharedManager.pushScope()
                break
            }
            
            parent = parent?.parent
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
        var newNode = node
        
        var newConds: [ConditionElementSyntax] = [ConditionElementSyntax]()
        node.conditions.forEach { condition in
            var newCondition = condition
            
            if let optBindingCondSyntax: OptionalBindingConditionSyntax = newCondition.condition.as(OptionalBindingConditionSyntax.self) {
                let varSymbol: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
                
                var newOptBindingCondSyntax: OptionalBindingConditionSyntax = optBindingCondSyntax
                
                if let idPattern: IdentifierPatternSyntax = optBindingCondSyntax.pattern.as(IdentifierPatternSyntax.self),
                   let confusedCondSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(idPattern.identifier.text),
                   let confusedCondSymbolName: String = SwiftConfusedHelper.confusedSymbol(confusedCondSymbol) {
                    
                    varSymbol.originalSymbol = idPattern.identifier.text
                    varSymbol.confusedSymbol = confusedCondSymbolName
                    
                    let newIdPattern: IdentifierPatternSyntax = idPattern.with(\.identifier, TokenSyntax(stringLiteral: confusedCondSymbolName)
                        .with(\.leadingTrivia, idPattern.identifier.leadingTrivia)
                        .with(\.trailingTrivia, idPattern.identifier.trailingTrivia)
                    )
                    
                    newOptBindingCondSyntax = newOptBindingCondSyntax.with(\.pattern, PatternSyntax(newIdPattern))
                }
                
                if let typeAnnotation = optBindingCondSyntax.typeAnnotation {
                    if let type: IdentifierTypeSyntax = typeAnnotation.type.as(IdentifierTypeSyntax.self),
                       let symbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(type.name.text),
                       let confusedSymbol = SwiftConfusedHelper.confusedSymbol(symbol) {
                        varSymbol.symbolType = type.name.text
                        
                        newOptBindingCondSyntax = newOptBindingCondSyntax
                            .with(\.typeAnnotation, typeAnnotation
                                .with(\.type, TypeSyntax(type
                                    .with(\.name, TokenSyntax(stringLiteral: confusedSymbol)
                            .with(\.leadingTrivia, typeAnnotation.type.leadingTrivia)
                            .with(\.trailingTrivia, typeAnnotation.type.trailingTrivia))))
                        )
                    }
                }
                
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(varSymbol)
                newCondition = condition.with(\.condition, ConditionElementSyntax.Condition(newOptBindingCondSyntax))
            }
            
            newConds.append(newCondition)
        }
        
        newNode = newNode.with(\.conditions, ConditionElementListSyntax(newConds)
            .with(\.leadingTrivia, newNode.conditions.leadingTrivia)
            .with(\.trailingTrivia, newNode.conditions.trailingTrivia))
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        if let idPattern: IdentifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self) {
            if idPattern.identifier.kind != .wildcardPattern {
                let tokenName: String = idPattern.identifier.text
                
                let varSymbol: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
                varSymbol.originalSymbol = tokenName
                varSymbol.parent = parentStack.last
                
                if let typeAnnotation = node.typeAnnotation,
                   let typeIdent: IdentifierTypeSyntax = typeAnnotation.type.as(IdentifierTypeSyntax.self) {
                    varSymbol.symbolType = typeIdent.name.text
                }
                
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(varSymbol)
            }
        }
        
        var newNode = node
        
        if let pattern: IdentifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self),
           let symbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(pattern.identifier.text),
           let confusedSymbol = SwiftConfusedHelper.confusedSymbol(symbol) {
            let newPattern = pattern.with(\.identifier, TokenSyntax(stringLiteral: confusedSymbol)
                .with(\.leadingTrivia, pattern.identifier.leadingTrivia)
                .with(\.trailingTrivia, pattern.identifier.trailingTrivia))
                .with(\.leadingTrivia, pattern.leadingTrivia)
                .with(\.trailingTrivia, pattern.trailingTrivia)
            
            newNode = newNode.with(\.pattern, PatternSyntax(newPattern))
        }
        
        if let typeAnnotation = node.typeAnnotation,
           let typeIdent: IdentifierTypeSyntax = typeAnnotation.type.as(IdentifierTypeSyntax.self),
           let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(typeIdent.name.text),
           let confusedSymbol = SwiftConfusedHelper.confusedSymbol(typeSymbol) {
            newNode = newNode.with(\.typeAnnotation,
                                    newNode.typeAnnotation?
                .with(\.type, TypeSyntax(IdentifierTypeSyntax(
                    leadingTrivia: newNode.typeAnnotation?.type.leadingTrivia,
                    name: TokenSyntax(stringLiteral: confusedSymbol),
                    trailingTrivia: newNode.typeAnnotation?.type.trailingTrivia)
                ))
            )
        }
        
        return super.visit(newNode)
    }
    
    override func visitPost(_ node: Syntax) {
        switch node.kind {
        case .variableDecl:
            parentStack.removeLast()
        case .classDecl, .functionDecl, .protocolDecl,
                .structDecl, .enumDecl:
            SwiftSourceScopeManager.sharedManager.popScope(true)
            parentStack.removeLast()
        case .forStmt, .repeatStmt, .doStmt, .whileStmt:
            SwiftSourceScopeManager.sharedManager.popScope(true)
        case .codeBlock: do {
            var parent = node.parent
            
            while parent != nil {
                if let _: GuardStmtSyntax = parent?.as(GuardStmtSyntax.self) {
                    SwiftSourceScopeManager.sharedManager.pushScope()
                    break
                }
                
                parent = parent?.parent
            }
        }
        default:
            break
        }
    }
}
