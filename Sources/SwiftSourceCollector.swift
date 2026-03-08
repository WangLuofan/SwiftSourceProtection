//
//  SwiftSourceCollector.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/13.
//

import SwiftSyntax
import Foundation

nonisolated(unsafe) var parentStack: [SwiftSourceSymbol] = [SwiftSourceSymbol]()
nonisolated(unsafe) var extensionMap: [String: SwiftSourceClassSymbol] = [String: SwiftSourceClassSymbol]()

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
        let clsSymbol: SwiftSourceClassSymbol = node.symbol(.class, self.sourceFile)
        
        parentStack.last?.children.append(clsSymbol)
        parentStack.append(clsSymbol)
        
        if let extSymbol: SwiftSourceClassSymbol = extensionMap[clsSymbol.originalSymbol] {
            clsSymbol.mergeSymbol(extSymbol)
        }
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(clsSymbol)

        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        parentStack.removeLast()
    }
    
    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        let funcSymbol: SwiftSourceFunctionSymbol = node.symbol(self.sourceFile)
        
        /// init方法设置为static
        funcSymbol.isStatic = true
        
        if let clsSymbol: SwiftSourceClassSymbol = parentStack.last as? SwiftSourceClassSymbol {
            clsSymbol.children.append(funcSymbol)
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let clsSymbol: SwiftSourceClassSymbol = node.symbol(.struct, self.sourceFile)
        
        parentStack.last?.children.append(clsSymbol)
        parentStack.append(clsSymbol)
        
        if let extSymbol: SwiftSourceClassSymbol = extensionMap[clsSymbol.originalSymbol] {
            clsSymbol.mergeSymbol(extSymbol)
        }
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(clsSymbol)
        return super.visit(node)
    }
    
    override func visitPost(_ node: StructDeclSyntax) {
        parentStack.removeLast()
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        let classSymbol: SwiftSourceClassSymbol = node.symbol(.extension, self.sourceFile)
        
        parentStack.append(classSymbol)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ExtensionDeclSyntax) {
        if let idExtType: IdentifierTypeSyntax = node.extendedType.as(IdentifierTypeSyntax.self),
           let extSymbol: SwiftSourceClassSymbol = parentStack.last as? SwiftSourceClassSymbol {
            if let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(idExtType.name.text) as? SwiftSourceClassSymbol {
                clsSymbol.mergeSymbol(extSymbol)
            } else {
                if let curExtSymbol: SwiftSourceClassSymbol = extensionMap[idExtType.name.text] {
                    curExtSymbol.mergeSymbol(extSymbol)
                } else {
                    extensionMap[idExtType.name.text] = extSymbol
                }
            }
        }
        
        parentStack.removeLast()
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let classSymbol: SwiftSourceClassSymbol = node.symbol(.protocol, self.sourceFile)
        
        parentStack.last?.children.append(classSymbol)
        parentStack.append(classSymbol)
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(classSymbol)
        return super.visit(node)
    }
    
    override func visitPost(_ node: ProtocolDeclSyntax) {
        parentStack.removeLast()
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // 收集成员方法和全局方法，排除局部方法
        if node.isMemberDecl || node.isGlobalDecl {
            let funcSymbol: SwiftSourceFunctionSymbol = node.symbol(self.sourceFile)

            if node.isMemberDecl {
                parentStack.last?.children.append(funcSymbol)
            } else {
                // 全局方法添加到 parentStack，在 visitPost 时加入全局作用域
                parentStack.append(funcSymbol)
            }
        }

        return super.visit(node)
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        if node.isGlobalDecl && parentStack.count == 1 {
            if let funcSymbol = parentStack.last {
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(funcSymbol)
            }
            parentStack.removeLast()
        }
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // 收集成员变量和全局变量，排除局部变量
        if node.isMemberDecl || node.isGlobalDecl {
            let variableSymbol = node.variableSymbol(self.sourceFile)

            if node.isMemberDecl {
                parentStack.last?.children.append(variableSymbol)
            } else {
                // 全局变量添加到 parentStack，在 visitPost 时加入全局作用域
                parentStack.append(variableSymbol)
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableSymbol)
            }
        }

        return super.visit(node)
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        if node.isGlobalDecl {
            parentStack.removeLast()
        }
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let enumSymbol: SwiftSourceClassSymbol = node.symbol(.enum, self.sourceFile)
        
        parentStack.last?.children.append(enumSymbol)
        parentStack.append(enumSymbol)
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(enumSymbol)
        return super.visit(node)
    }
    
    override func visitPost(_ node: EnumDeclSyntax) {
        parentStack.removeLast()
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
            enumCaseInfo.ASTNode = node
            enumCaseInfo.symbolType = enumCaseInfo.parent?.originalSymbol
            
            parentStack.last?.children.append(enumCaseInfo)
        }
        
        return super.visit(node)
    }
}
