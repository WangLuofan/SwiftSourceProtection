//
//  SwiftSourceCollector.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/13.
//

import SwiftSyntax
import Foundation

class SwiftSourceCollector: SyntaxVisitor {
    var sourceFile: String
    var sourceKitten: SourceKittenHandler?
    
    private lazy var parentStack: [SwiftSourceSymbol] = [SwiftSourceSymbol]()
    
    init(sourceFile: String, sourceKitten: SourceKittenHandler?) {
        self.sourceFile = sourceFile
        self.sourceKitten = sourceKitten
        
        super.init(viewMode: .sourceAccurate)
    }
   
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SwiftSourceSymbol = node.symbol(.class, self.sourceFile)
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        
        if !self.parentStack.isEmpty {
            symbol.parent = parentStack.last
        }
        
        self.parentStack.append(symbol)
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
    }
    
    override func visit(_ node: MemberBlockSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: MemberBlockSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope(false)
    }
    
    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: CodeBlockSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope(false)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SwiftSourceSymbol = node.symbol(self.sourceFile)
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        
        if !self.parentStack.isEmpty {
            if node.isMemberDecl,
               let clsSymbol: SwiftSourceClassSymbol = self.parentStack.last as? SwiftSourceClassSymbol {
                clsSymbol.members.append(symbol)
            }
            
            symbol.parent = self.parentStack.last
        }
        
        self.parentStack.append(symbol)
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
    }
    
    override func visit(_ node: FunctionParameterListSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionParameterListSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope(false)
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SwiftSourceSymbol = node.funcParameterSymbol(self.sourceFile)
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        
        if !self.parentStack.isEmpty {
            symbol.parent = self.parentStack.removeLast()
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SwiftSourceSymbol = node.variableSymbol(self.sourceFile)
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        
        if !self.parentStack.isEmpty {
            if node.isMemberDecl,
               let clsSymbol: SwiftSourceClassSymbol = self.parentStack.last as? SwiftSourceClassSymbol {
                clsSymbol.members.append(symbol)
            }
            
            symbol.parent = self.parentStack.last
        }
        
        self.parentStack.append(symbol)
        return super.visit(node)
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
    }
    
    override func visit(_ node: ClosureParameterSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SwiftSourceSymbol = node.closureParameterSymbol(self.sourceFile)
        
        if self.parentStack.isEmpty {
            symbol.parent = self.parentStack.last
        }
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureCaptureListSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClosureCaptureListSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope(true)
    }
}
