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
        let clsSymbol: SwiftSourceClassSymbol = node.classSymbol(self.sourceFile)
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(clsSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        parentStack.last?.children.append(clsSymbol)
        parentStack.append(clsSymbol)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        var funcSymbol: SwiftSourceFunctionSymbol = SwiftSourceFunctionSymbol()
        funcSymbol.originalSymbol = "init"
        
        return super.visit(node)
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let classSymbol: SwiftSourceClassSymbol = node.classSymbol(self.sourceFile)
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(classSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        parentStack.last?.children.append(classSymbol)
        parentStack.append(classSymbol)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: StructDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let classSymbol: SwiftSourceClassSymbol = node.classSymbol(self.sourceFile)
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(classSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        parentStack.last?.children.append(classSymbol)
        parentStack.append(classSymbol)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ProtocolDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // 收集成员方法和全局方法，排除局部方法
        if node.isMemberDecl || node.isGlobalDecl {
            let funcSymbol: SwiftSourceFunctionSymbol = node.functionSymbol(self.sourceFile)
            
            SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(funcSymbol)
            parentStack.last?.children.append(funcSymbol)
        }

        return super.visit(node)
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let variableSymbol = node.variableSymbol(self.sourceFile)

        // 收集成员变量和全局变量，排除局部变量
        if node.isMemberDecl || node.isGlobalDecl {
            SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableSymbol)
            parentStack.last?.children.append(variableSymbol)
        }

        return super.visit(node)
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let enumInfo: SwiftSourceClassSymbol = node.classSymbol(self.sourceFile)
        
        parentStack.last?.children.append(enumInfo)
        parentStack.append(enumInfo)
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(enumInfo)
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: EnumDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        node.elements.forEach { enumCaseElemSyntax in
            let enumCaseInfo: SwiftSourceEnumCaseSymbol = SwiftSourceEnumCaseSymbol(nodeKind: .enumCase)
            enumCaseInfo.originalSymbol = enumCaseElemSyntax.name.text
            enumCaseInfo.symbolFilePath = self.sourceFile
            enumCaseInfo.isMember = node.isMemberDecl
            enumCaseElemSyntax.parameterClause?.parameters.forEach { enumCaseParamDecl in
                if let identTypeSyntax: IdentifierTypeSyntax = enumCaseParamDecl.type.as(IdentifierTypeSyntax.self) {
                    enumCaseInfo.associatedType.append(identTypeSyntax.name.text)
                }
            }
            
            enumCaseInfo.parent = parentStack.last
            parentStack.last?.children.append(enumCaseInfo)
            SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(enumCaseInfo)
        }
        
        return super.visit(node)
    }
}
