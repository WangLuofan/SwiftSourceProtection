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
        
        let newNode = node
            .with(\.name, .identifier(confusedSymbolName)
                .with(\.leadingTrivia, node.name.leadingTrivia)
                .with(\.trailingTrivia, node.name.trailingTrivia)
            )
        
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(newNode)
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
            if let idPatternSyntax: IdentifierPatternSyntax = binding.pattern.as(IdentifierPatternSyntax.self) {
                guard let confusedSymbolName: String = varSymbol.confusedSymbolName else {
                    newBindings.append(binding)
                    return
                }
                
                let newPattern: IdentifierPatternSyntax = idPatternSyntax
                    .with(\.identifier, .identifier(confusedSymbolName)
                        .with(\.leadingTrivia, idPatternSyntax.identifier.leadingTrivia)
                        .with(\.trailingTrivia, idPatternSyntax.identifier.trailingTrivia)
                    )
                let newBinding = binding.with(\.pattern, PatternSyntax(newPattern))
                newBindings.append(newBinding)
                
                return
            }
            
            newBindings.append(binding)
        }
        
        let newNode = node
            .with(\.bindings, PatternBindingListSyntax(newBindings)
                .with(\.leadingTrivia, node.bindings.leadingTrivia)
                .with(\.trailingTrivia, node.bindings.trailingTrivia)
            )
        
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        SPSwiftSourceScopeManager.sharedManager.pushScope(false)
        
        var newParameters: [FunctionParameterSyntax] = []
        node.signature.parameterClause.parameters.forEach { parameter in
            if let secondName: TokenSyntax = parameter.secondName,
               let paramSymbol: SPSwiftSourceVariableSymbol = SPSwiftSourceScopeManager.sharedManager.findSymbolWithSymbolName(secondName.text) as? SPSwiftSourceVariableSymbol,
               let confusedParamName: String = paramSymbol.confusedSymbolName {
                newParameters.append(parameter
                    .with(\.secondName,
                        .identifier(confusedParamName)
                        .with(\.leadingTrivia, secondName.leadingTrivia)
                        .with(\.trailingTrivia, secondName.trailingTrivia)
                    )
                )
                
                return
            }
            
            newParameters.append(parameter)
        }
        
        let newNode = node.with(\.signature, node.signature.with(\.parameterClause, node.signature.parameterClause.with(\.parameters, FunctionParameterListSyntax(newParameters))))
        
        return super.visit(newNode)
    }
    
    override func visitPost(_ node: Syntax) {
        switch node.kind {
        case .classDecl, .variableDecl, .functionDecl:
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
}
