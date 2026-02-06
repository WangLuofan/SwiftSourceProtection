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
    
    init(projectPath: String) {
        self.projectPath = projectPath
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let clsName: String = node.name.text
        
        guard let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsName) as? SwiftSourceClassSymbol,
              let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol) else {
            return super.visit(node)
        }
        
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        let clsName: String = node.name.text
        
        guard let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsName) as? SwiftSourceClassSymbol,
              let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol) else {
            return super.visit(node)
        }
        
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        guard let extendedType = node.extendedType.as(IdentifierTypeSyntax.self),
              let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(extendedType.name.text) as? SwiftSourceClassSymbol,
              let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol) else {
            return super.visit(node)
        }
        
        let newNode = node.with(\.extendedType,
                                 TypeSyntax(IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: confusedSymbolName)))
            .with(\.leadingTrivia, node.extendedType.leadingTrivia)
            .with(\.trailingTrivia, node.extendedType.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visitPost(_ node: Syntax) {
        if let _ = node.as(ClassDeclSyntax.self) {
            SwiftSourceScopeManager.sharedManager.popScope(true)
        }
    }
}
