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
    
    private var currentFunction: SPSwiftSourceFunctionSymbol?
    
    init(sourceTree: SourceFileSyntax, sourceFile: File) {
        self.sourceTree = sourceTree
        self.sourceFile = sourceFile
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        guard let classSymbol: SPSwiftSourceClassSymbol = SPSwiftSourceScopeManager.sharedManager.findSymbolWithSymbolName(node.name.text) as? SPSwiftSourceClassSymbol,
              let confusedSymbolName: String = classSymbol.confusedSymbolName else {
            return super.visit(node)
        }
        
        let newNode = node.with(\.name, .identifier(confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia)
        )
        
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        var variableName: String = ""
        node.bindings.forEach { binding in
            if let idPatternSyntax: IdentifierPatternSyntax = binding.pattern.as(IdentifierPatternSyntax.self) {
                variableName = idPatternSyntax.identifier.text
            }
        }
        
        guard let varSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceScopeManager.sharedManager.findSymbolWithSymbolName(variableName) as? SPSwiftSourceVariableSymbol else {
            return super.visit(node)
        }
        
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
        
        let newNode = node.with(\.bindings, PatternBindingListSyntax(newBindings)
                .with(\.leadingTrivia, node.bindings.leadingTrivia)
                .with(\.trailingTrivia, node.bindings.trailingTrivia)
            )
        
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
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
        
        if let currentFunction,
           let funcDecl: FunctionDeclSyntax = self.nodeParent(node) {
            for (index, parameter) in funcDecl.signature.parameterClause.parameters.enumerated() {
                if parameter != node {
                    continue
                }
                
                if index < currentFunction.confusedLabels.count {
                    newNode = newNode.with(\.firstName, .identifier(currentFunction.confusedLabels[index], leadingTrivia: node.firstName.leadingTrivia, trailingTrivia: node.firstName.trailingTrivia))
                    if let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceScopeManager.sharedManager.findSymbolWithSymbolName(currentFunction.labels[index]) as? SPSwiftSourceVariableSymbol {
                        paramSymbol.confusedSymbolName = currentFunction.confusedLabels[index]
                    }
                }
                
                if let secondName = node.secondName {
                    let confusedSymbolName = ConfuseHelper.confusedSymbolName(secondName.text)
                    newNode = newNode.with(\.secondName, .identifier(confusedSymbolName, leadingTrivia: secondName.leadingTrivia, trailingTrivia: secondName.trailingTrivia))
                }
            }
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureShorthandParameterSyntax) -> ClosureShorthandParameterSyntax {
        var newNode = node
        
        if let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceScopeManager.sharedManager.findSymbolWithSymbolName(node.name.text) as? SPSwiftSourceVariableSymbol,
           let confusedSymbolName = paramSymbol.confusedSymbolName {
            newNode = newNode.with(\.name, .identifier(confusedSymbolName, leadingTrivia: newNode.name.leadingTrivia, trailingTrivia: newNode.name.trailingTrivia))
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClosureParameterSyntax) -> ClosureParameterSyntax {
        var newNode = node
        
        if let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceScopeManager.sharedManager.findSymbolWithSymbolName(newNode.firstName.text) as? SPSwiftSourceVariableSymbol,
           let confusedSymbolName = paramSymbol.confusedSymbolName {
            newNode = newNode.with(\.firstName, .identifier(confusedSymbolName, leadingTrivia: newNode.firstName.leadingTrivia, trailingTrivia: newNode.firstName.trailingTrivia))
        }

        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var newNode = node
        let sig: String = ConfuseHelper.generateFunctionSignature(node)
        
        if let funcSymbol: SPSwiftSourceFunctionSymbol = SPSwiftSourceScopeManager.sharedManager.findSymbolWithSymbolName(sig) as? SPSwiftSourceFunctionSymbol {
            if let confusedFunctionName: String = funcSymbol.confusedFunctionName {
                newNode = newNode.with(\.name, .identifier(confusedFunctionName, leadingTrivia: newNode.name.leadingTrivia, trailingTrivia: newNode.name.trailingTrivia))
            }
            
            self.currentFunction = funcSymbol
        }
        
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        var newNode = node
        
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        if let idPattern: IdentifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self),
           let symbol: SPSwiftSourceVariableSymbol = SPSwiftSourceScopeManager.sharedManager.findSymbolWithSymbolName(idPattern.identifier.text) as? SPSwiftSourceVariableSymbol,
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
        
        if let baseSymbol: SPSwiftSourceSymbol = SPSwiftSourceScopeManager.sharedManager.findSymbolWithSymbolName(node.baseName.text),
           let confusedSymbolName = baseSymbol.confusedSymbolName {
            newNode = newNode.with(\.baseName,
                .identifier(confusedSymbolName, leadingTrivia: newNode.baseName.leadingTrivia, trailingTrivia: newNode.baseName.trailingTrivia)
            )
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        var newNode = node
        
        if let typeSymbol: SPSwiftSourceSymbol = SPSwiftSourceScopeManager.sharedManager.findSymbolWithSymbolName(node.name.text),
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
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: SwitchDefaultLabelSyntax) -> SwitchDefaultLabelSyntax {
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visitPost(_ node: Syntax) {
        switch node.kind {
        case .functionDecl:
            self.currentFunction = nil
            fallthrough
        case .classDecl, .variableDecl, .whileStmt, .forStmt,
                .closureExpr, .extensionDecl, .ifExpr, .switchExpr, .switchCase,
                .switchDefaultLabel:
            SPSwiftSourceScopeManager.sharedManager.popScope(true)
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
