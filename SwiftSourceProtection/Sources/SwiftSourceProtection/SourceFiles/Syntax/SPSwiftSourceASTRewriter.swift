//
//  SPSwiftSourceASTRewriter.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import Foundation
import SwiftSyntax

class SPSwiftSourceASTRewriter: SyntaxRewriter {
    private var sourceTree: SourceFileSyntax
    private var sourceFile: File
    private var topScope: SPSwiftSourceScope
    private var currentScope: SPSwiftSourceScope
    
    private var currentFunction: DeclSyntaxProtocol?
    
    init(sourceTree: SourceFileSyntax, sourceFile: File, scope: SPSwiftSourceScope) {
        self.sourceTree = sourceTree
        self.sourceFile = sourceFile
        self.topScope = scope
        self.currentScope = scope
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        var newNode = node
        if let classSymbol: SPSwiftSourceClassSymbol = self.currentScope.findSymbolWithSymbolName(node.name.text) as? SPSwiftSourceClassSymbol,
              let confusedSymbolName: String = classSymbol.confusedSymbolName {
            newNode = newNode.with(\.name, .identifier(confusedSymbolName, leadingTrivia: node.name.leadingTrivia, trailingTrivia: node.name.trailingTrivia)
            )
        }
        
        self.currentScope = self.currentScope.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        self.currentScope = self.currentScope.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        var variableName: String = ""
        node.bindings.forEach { binding in
            if let idPatternSyntax: IdentifierPatternSyntax = binding.pattern.as(IdentifierPatternSyntax.self) {
                variableName = idPatternSyntax.identifier.text
            }
        }
        
        if let varSymbol: SPSwiftSourceVariableSymbol = self.currentScope.findSymbolWithSymbolName(variableName) as? SPSwiftSourceVariableSymbol {
            var newBindings: [PatternBindingSyntax] = []
            node.bindings.forEach { binding in
                
                var newBinding = binding
                if let idPatternSyntax: IdentifierPatternSyntax = binding.pattern.as(IdentifierPatternSyntax.self) {
                    guard let confusedSymbolName: String = varSymbol.confusedSymbolName else {
                        newBindings.append(binding)
                        return
                    }
                    
                    let newPattern: IdentifierPatternSyntax = idPatternSyntax.with(\.identifier, .identifier(confusedSymbolName)
                        .with(\.leadingTrivia, idPatternSyntax.identifier.leadingTrivia)
                        .with(\.trailingTrivia, idPatternSyntax.identifier.trailingTrivia)
                    )
                    
                    newBinding = newBinding.with(\.pattern, PatternSyntax(newPattern)
                        .with(\.leadingTrivia, binding.pattern.leadingTrivia)
                        .with(\.trailingTrivia, binding.pattern.trailingTrivia)
                    )
                }
                
                newBindings.append(newBinding)
            }
            
            newNode = newNode.with(\.bindings, PatternBindingListSyntax(newBindings)
                .with(\.leadingTrivia, node.bindings.leadingTrivia)
                .with(\.trailingTrivia, node.bindings.trailingTrivia)
            )
        }
        
        self.currentScope = self.currentScope.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: TupleTypeElementSyntax) -> TupleTypeElementSyntax {
        var newNode = node
        
        if let firstName = newNode.firstName {
            let confusedFirstName: String = ConfuseHelper.confusedSymbolName(firstName.text)
            newNode = newNode.with(\.firstName, .identifier(confusedFirstName, leadingTrivia: firstName.leadingTrivia, trailingTrivia: firstName.trailingTrivia))
        }
        
        if let secondName = newNode.secondName {
            let confusedSecondName: String = ConfuseHelper.confusedSymbolName(secondName.text)
            newNode = newNode.with(\.secondName, .identifier(confusedSecondName, leadingTrivia: secondName.leadingTrivia, trailingTrivia: secondName.trailingTrivia))
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
        var newNode = node
        
        var parameters: FunctionParameterListSyntax?
        if let funcDecl: FunctionDeclSyntax = self.nodeParent(node) {
            parameters = funcDecl.signature.parameterClause.parameters
        } else if let initDecl: InitializerDeclSyntax = self.nodeParent(node) {
            parameters = initDecl.signature.parameterClause.parameters
        }
        
        guard let parameters, !parameters.isEmpty else {
            return super.visit(newNode)
        }
        
        for (_, parameter) in parameters.enumerated() {
            if parameter != node {
                continue
            }
            
            if let secondName = node.secondName,
               let paramSymbol: SPSwiftSourceVariableSymbol = self.currentScope.findSymbolWithSymbolName(secondName.text) as? SPSwiftSourceVariableSymbol,
               let confusedSymbolName = paramSymbol.confusedSymbolName {
                newNode = newNode.with(\.secondName, .identifier(confusedSymbolName, leadingTrivia: secondName.leadingTrivia, trailingTrivia: secondName.trailingTrivia))
            }
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        self.currentScope = self.currentScope.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureShorthandParameterSyntax) -> ClosureShorthandParameterSyntax {
        var newNode = node
        
        if let paramSymbol: SPSwiftSourceVariableSymbol = self.currentScope.findSymbolWithSymbolName(node.name.text) as? SPSwiftSourceVariableSymbol,
           let confusedSymbolName = paramSymbol.confusedSymbolName {
            newNode = newNode.with(\.name, .identifier(confusedSymbolName, leadingTrivia: newNode.name.leadingTrivia, trailingTrivia: newNode.name.trailingTrivia))
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        self.currentFunction = node
        self.currentScope = self.currentScope.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureParameterSyntax) -> ClosureParameterSyntax {
        var newNode = node
        
        if let paramSymbol: SPSwiftSourceVariableSymbol = self.currentScope.findSymbolWithSymbolName(newNode.firstName.text) as? SPSwiftSourceVariableSymbol,
           let confusedSymbolName = paramSymbol.confusedSymbolName {
            newNode = newNode.with(\.firstName, .identifier(confusedSymbolName, leadingTrivia: newNode.firstName.leadingTrivia, trailingTrivia: newNode.firstName.trailingTrivia))
        }

        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var newNode = node
        let sig: String = ConfuseHelper.generateSignature(funcName: node.name.text, parameters: node.signature.parameterClause.parameters)
        
        if let funcSymbol: SPSwiftSourceFunctionSymbol = self.currentScope.findSymbolWithSymbolName(sig) as? SPSwiftSourceFunctionSymbol,
           let confusedFunctionName: String = funcSymbol.confusedFunctionName {
            newNode = newNode.with(\.name, .identifier(confusedFunctionName, leadingTrivia: newNode.name.leadingTrivia, trailingTrivia: newNode.name.trailingTrivia))
        }
        
        self.currentFunction = node
        self.currentScope = self.currentScope.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
        self.currentScope = self.currentScope.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        var newNode = node
        
        self.currentScope = self.currentScope.pushScope(false)
        if let idPattern: IdentifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self),
           let symbol: SPSwiftSourceVariableSymbol = self.currentScope.findSymbolWithSymbolName(idPattern.identifier.text) as? SPSwiftSourceVariableSymbol,
           let confusedSymbolName = symbol.confusedSymbolName {
            newNode = newNode.with(\.pattern, PatternSyntax(idPattern
                .with(\.identifier, .identifier(confusedSymbolName, leadingTrivia: idPattern.identifier.leadingTrivia)
                    .with(\.trailingTrivia, idPattern.identifier.trailingTrivia))
            ))
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
        var newNode = node
        
        if let baseSymbol: SPSwiftSourceSymbol = self.currentScope.findSymbolWithSymbolName(node.baseName.text),
           let confusedSymbolName = baseSymbol.confusedSymbolName {
            newNode = newNode.with(\.baseName,
                .identifier(confusedSymbolName, leadingTrivia: newNode.baseName.leadingTrivia, trailingTrivia: newNode.baseName.trailingTrivia)
            )
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        var newNode = node
        
        if let typeSymbol: SPSwiftSourceSymbol = self.currentScope.findSymbolWithSymbolName(node.name.text),
           let confusedSymbolName = typeSymbol.confusedSymbolName {
            newNode = newNode.with(\.name, .identifier(
                confusedSymbolName,
                leadingTrivia: node.name.leadingTrivia,
                trailingTrivia: node.name.trailingTrivia)
            )
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        self.currentScope = self.currentScope.pushScope(false)
        
        var confusedConditions: [ConditionElementSyntax] = []
        node.conditions.forEach { condition in
            if let optBindCondSyntax: OptionalBindingConditionSyntax = condition.condition.as(OptionalBindingConditionSyntax.self),
               let idPattern: IdentifierPatternSyntax = optBindCondSyntax.pattern.as(IdentifierPatternSyntax.self),
               let varSymbol: SPSwiftSourceVariableSymbol = self.currentScope.findSymbolWithSymbolName(idPattern.identifier.text) as? SPSwiftSourceVariableSymbol,
               let confusedSymbolName = varSymbol.confusedSymbolName {
                confusedConditions.append(condition
                    .with(\.condition, ConditionElementSyntax.Condition(optBindCondSyntax
                        .with(\.pattern, PatternSyntax(idPattern
                            .with(\.identifier, .identifier(confusedSymbolName, leadingTrivia: idPattern.identifier.leadingTrivia, trailingTrivia: idPattern.identifier.trailingTrivia))
                        ))
                    ))
                )
            } else {
                confusedConditions.append(condition)
            }
        }
        
        let newNode = node.with(\.conditions, ConditionElementListSyntax(confusedConditions)
            .with(\.leadingTrivia, node.conditions.leadingTrivia)
            .with(\.trailingTrivia, node.conditions.trailingTrivia)
        )
        return super.visit(newNode)
    }
    
    override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
        self.currentScope = self.currentScope.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        self.currentScope = self.currentScope.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: SwitchDefaultLabelSyntax) -> SwitchDefaultLabelSyntax {
        self.currentScope = self.currentScope.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
        var newNode = node
        var confusedConditions: [ConditionElementSyntax] = []
        
        node.conditions.forEach { condition in
            if let optBindCondSyntax: OptionalBindingConditionSyntax = condition.condition.as(OptionalBindingConditionSyntax.self) {
                if let idPattern: IdentifierPatternSyntax = optBindCondSyntax.pattern.as(IdentifierPatternSyntax.self),
                   let paramSymbol: SPSwiftSourceVariableSymbol = self.currentScope.findSymbolWithSymbolName(idPattern.identifier.text) as? SPSwiftSourceVariableSymbol,
                   let confusedSymbolName = paramSymbol.confusedSymbolName {
                    confusedConditions.append(condition
                        .with(\.condition, ConditionElementSyntax.Condition(optBindCondSyntax
                            .with(\.pattern, PatternSyntax(idPattern
                                .with(\.identifier, .identifier(confusedSymbolName, leadingTrivia: idPattern.identifier.leadingTrivia, trailingTrivia: idPattern.identifier.trailingTrivia)
                                     )
                            ))
                        ))
                    )
                } else {
                    confusedConditions.append(condition)
                }
            } else {
                confusedConditions.append(condition)
            }
        }
        
        newNode = newNode.with(\.conditions, ConditionElementListSyntax(confusedConditions)
            .with(\.leadingTrivia, newNode.conditions.leadingTrivia)
            .with(\.trailingTrivia, newNode.conditions.trailingTrivia)
        )
        self.currentScope = self.currentScope.pushScope(false)
        
        return super.visit(newNode)
    }
    
    override func visitPost(_ node: Syntax) {
        switch node.kind {
        case .functionDecl:
            self.currentFunction = nil
            fallthrough
        case .classDecl, .variableDecl, .whileStmt, .forStmt,
                .closureExpr, .extensionDecl, .ifExpr, .switchExpr, .switchCase,
                .switchDefaultLabel, .guardStmt, .initializerDecl:
            self.currentScope = self.currentScope.popScope(true)
        default:
            break
        }
    }
}

extension SPSwiftSourceASTRewriter {
    func rewrite() -> String {
        let rewritten = self.visit(self.sourceTree)
        return rewritten.description
    }
    
    private func nodeParent<T: SyntaxProtocol>(_ node: SyntaxProtocol) -> T? {
        var parent = node.parent
        while parent != nil {
            if let parent: T = parent?.as(T.self) {
                return parent
            }
            
            parent = parent?.parent
        }
        
        return nil
    }
}
