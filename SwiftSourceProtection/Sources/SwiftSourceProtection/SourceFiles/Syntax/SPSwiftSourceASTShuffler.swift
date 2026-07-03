//
//  SPSwiftSourceASTShuffler.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/7/3.
//

import SwiftSyntax

class SPSwiftSourceASTShuffler: SyntaxRewriter {
    private var sourceTree: SourceFileSyntax
    private var sourceFile: File
    
    init(sourceTree: SourceFileSyntax, sourceFile: File) {
        self.sourceTree = sourceTree
        self.sourceFile = sourceFile
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        var newNode = node
        
        var importDecls: [CodeBlockItemSyntax] = []
        var nonImportDecls: [CodeBlockItemSyntax] = []
        
        node.statements.forEach {
            if let importDeclSyntax: ImportDeclSyntax = $0.item.as(ImportDeclSyntax.self) {
                importDecls.append($0)
            } else {
                nonImportDecls.append($0)
            }
        }
        
        importDecls.shuffle()
        nonImportDecls.shuffle()
        
        newNode = newNode.with(\.statements, CodeBlockItemListSyntax(importDecls + nonImportDecls)
            .with(\.leadingTrivia, newNode.statements.leadingTrivia)
            .with(\.trailingTrivia, newNode.statements.trailingTrivia)
        )
        
        return super.visit(newNode)
    }
}

extension SPSwiftSourceASTShuffler {
    func shuffle() -> SourceFileSyntax {
        let rewritedSyntax: SourceFileSyntax = self.visit(self.sourceTree)
        return rewritedSyntax
    }
}
