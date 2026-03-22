
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
    private let sourceFile: String
    
    init(sourceFile: String) {
        self.sourceFile = sourceFile
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        
        guard let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager
            .findSymbol(node, inFile: self.sourceFile) as? SwiftSourceClassSymbol else {
            return super.visit(node)
        }
        
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        
        let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol)
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        
        guard let proSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager
            .findSymbol(node, inFile: self.sourceFile) as? SwiftSourceClassSymbol else {
            return super.visit(node)
        }
        
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        
        let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(proSymbol)
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
}
