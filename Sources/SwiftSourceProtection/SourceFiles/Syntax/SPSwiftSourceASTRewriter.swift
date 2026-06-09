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
        return super.visit(newNode)
    }
    
    override func visitPost(_ node: Syntax) {
        
    }
}

extension SPSwiftSourceASTRewriter {
    func rewrite() -> String {
        let rewritten = self.visit(self.sourceTree)
        return rewritten.description
    }
}
