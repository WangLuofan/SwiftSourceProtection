//
//  SwiftSourceCollector.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/13.
//

import SwiftSyntax
import Foundation

nonisolated(unsafe) var parentStack: [SwiftSourceSymbol] = [SwiftSourceSymbol]()

class SwiftSourceCollector: SyntaxVisitor {
    var sourceFile: String
    
    deinit {
        parentStack.removeAll()
    }
    
    init(sourceFile: String) {
        self.sourceFile = sourceFile
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let classSymbol: SwiftSourceSymbol = SwiftSourceSymbol()
        
        classSymbol.symbolFilePath = self.sourceFile
        classSymbol.ASTNode = node
        classSymbol.nodeType = .class
        classSymbol.parent = parentStack.last
        classSymbol.originalSymbol = node.name.text
        classSymbol.identifier = node.name.text
        classSymbol.inheritedType = node.inheritanceClause?.inheritedTypes.compactMap({ $0.as(IdentifierTypeSyntax.self)?.name.text })
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(classSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        parentStack.append(classSymbol)
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.sharedManager.popScope()
    }
}
