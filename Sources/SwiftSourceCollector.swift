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
        let classSymbol: SwiftSourceClassSymbol = SwiftSourceClassSymbol(nodeKind: .class)
        
        classSymbol.symbolFilePath = self.sourceFile
        classSymbol.ASTNode = node
        classSymbol.parent = parentStack.last
        classSymbol.originalSymbol = node.name.text
        classSymbol.inheritedType = node.inheritanceClause?.inheritedTypes.compactMap({ $0.as(IdentifierTypeSyntax.self)?.name.text })
        node.modifiers.forEach { modifier in
            classSymbol.accessControl = modifier.accessControl
            classSymbol.isFinal = modifier.isFinal
        }
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(classSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        parentStack.last?.children.append(classSymbol)
        parentStack.append(classSymbol)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let classSymbol: SwiftSourceClassSymbol = SwiftSourceClassSymbol(nodeKind: .struct)
        
        classSymbol.symbolFilePath = self.sourceFile
        classSymbol.ASTNode = node
        classSymbol.parent = parentStack.last
        classSymbol.originalSymbol = node.name.text
        classSymbol.inheritedType = node.inheritanceClause?.inheritedTypes.compactMap({ $0.as(IdentifierTypeSyntax.self)?.name.text })
        node.modifiers.forEach { modifier in
            classSymbol.accessControl = modifier.accessControl
            classSymbol.isFinal = modifier.isFinal
        }
        
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
        let classSymbol: SwiftSourceClassSymbol = SwiftSourceClassSymbol(nodeKind: .protocol)
        
        classSymbol.symbolFilePath = self.sourceFile
        classSymbol.ASTNode = node
        classSymbol.parent = parentStack.last
        classSymbol.originalSymbol = node.name.text
        classSymbol.inheritedType = node.inheritanceClause?.inheritedTypes.compactMap({ $0.as(IdentifierTypeSyntax.self)?.name.text })
        node.modifiers.forEach { modifier in
            classSymbol.accessControl = modifier.accessControl
            classSymbol.isFinal = modifier.isFinal
        }
        
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
        
        let funcSymbol: SwiftSourceFunctionSymbol = SwiftSourceFunctionSymbol(nodeKind: .function)
        funcSymbol.symbolFilePath = self.sourceFile
        funcSymbol.ASTNode = node
        funcSymbol.parent = parentStack.last
        funcSymbol.originalSymbol = node.name.text
        node.modifiers.forEach { modifier in
            funcSymbol.accessControl = modifier.accessControl
            funcSymbol.isStatic = modifier.isStatic
            funcSymbol.isFinal = modifier.isFinal
            funcSymbol.isClass = modifier.isClass
            funcSymbol.isOverride = modifier.isOverride
        }
        
        funcSymbol.returnType = "Void"
        if let identSyntax: IdentifierTypeSyntax = node.signature.returnClause?.type.as(IdentifierTypeSyntax.self) {
            funcSymbol.returnType = identSyntax.name.text
        }
        
        funcSymbol.isMember = node.isMemberDecl
        
        // symbol|static|return|parameter
        var funcSignature: String = "\(node.name.text)|\(funcSymbol.isStatic ? "static" : "")|\(funcSymbol.returnType)|("
        var isFirstParameter: Bool = true
        node.signature.parameterClause.parameters.forEach { parameterSyntax in
            let funcLabel: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .label)
            funcLabel.ASTNode = parameterSyntax
            funcLabel.parent = parentStack.last
            funcLabel.originalSymbol = parameterSyntax.firstName.text
            funcLabel.symbolFilePath = self.sourceFile
            funcSymbol.labels[parameterSyntax.firstName.text] = funcLabel
            
            if !isFirstParameter {
                funcSignature.append(", ")
            }
            
            funcSignature.append("\(parameterSyntax.firstName.text)")
            if let typeSyntax: IdentifierTypeSyntax = parameterSyntax.type.as(IdentifierTypeSyntax.self) {
                funcSignature.append(": \(typeSyntax.name.text)")
            }
            
            isFirstParameter = false
        }
        
        funcSignature.append(")")
        funcSymbol.identifier = funcSignature

        // 收集成员方法和全局方法，排除局部方法
        if node.isMemberDecl || node.isGlobalDecl {
            SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(funcSymbol)
            parentStack.last?.children.append(funcSymbol)
        }

        return super.visit(node)
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        
        let variableSymbol: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
        variableSymbol.symbolFilePath = self.sourceFile
        variableSymbol.ASTNode = node
        variableSymbol.parent = parentStack.last
        node.modifiers.forEach { modifier in
            variableSymbol.accessControl = modifier.accessControl
            variableSymbol.isStatic = modifier.isStatic
            variableSymbol.isFinal = modifier.isFinal
            variableSymbol.isClass = modifier.isClass
            variableSymbol.isOverride = modifier.isOverride
        }
        node.bindings.forEach { [weak variableSymbol] patternBinding in
            guard let variableSymbol else {
                return
            }
            
            if let identPatternBinding: IdentifierPatternSyntax = patternBinding.pattern.as(IdentifierPatternSyntax.self) {
                variableSymbol.originalSymbol = identPatternBinding.identifier.text
            }
            
            if let typeAnnontation: TypeAnnotationSyntax = patternBinding.typeAnnotation {
                variableSymbol.symbolType = typeAnnontation.type.trimmedDescription
            }
        }
        variableSymbol.isMember = node.isMemberDecl

        // 收集成员变量和全局变量，排除局部变量
        if node.isMemberDecl || node.isGlobalDecl {
            SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableSymbol)

            parentStack.last?.children.append(variableSymbol)
        }

        return super.visit(node)
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let enumInfo: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .enum)
        
        enumInfo.originalSymbol = node.name.text
        enumInfo.symbolFilePath = self.sourceFile
        enumInfo.isMember = node.isMemberDecl
        enumInfo.ASTNode = node
        enumInfo.parent = parentStack.last
        
        node.modifiers.forEach { modifier in
            enumInfo.accessControl = modifier.accessControl
            enumInfo.isStatic = modifier.isStatic
            enumInfo.isFinal = modifier.isFinal
            enumInfo.isClass = modifier.isClass
            enumInfo.isOverride = modifier.isOverride
        }
        
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
            enumCaseInfo.ASTNode = enumCaseElemSyntax
            enumCaseElemSyntax.parameterClause?.parameters.forEach { enumCaseParamDecl in
                if let identTypeSyntax: IdentifierTypeSyntax = enumCaseParamDecl.type.as(IdentifierTypeSyntax.self) {
                    enumCaseInfo.associatedType.append(identTypeSyntax.name.text)
                }
            }
            
            enumCaseInfo.parent = parentStack.last
            SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(enumCaseInfo)
        }
        
        return super.visit(node)
    }
}
