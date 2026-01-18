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
        let classSymbol: SwiftSourceClassSymbol = SwiftSourceClassSymbol(nodeType: .class)
        
        classSymbol.symbolFilePath = self.sourceFile
        classSymbol.ASTNode = node
        classSymbol.parent = parentStack.last
        classSymbol.originalSymbol = node.name.text
        classSymbol.identifier = node.name.text
        classSymbol.inheritedType = node.inheritanceClause?.inheritedTypes.compactMap({ $0.as(IdentifierTypeSyntax.self)?.name.text })
        node.modifiers.forEach { modifier in
            classSymbol.accessControl = modifier.accessControl
            classSymbol.isFinal = modifier.isFinal
        }
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(classSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        parentStack.append(classSymbol)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let classSymbol: SwiftSourceClassSymbol = SwiftSourceClassSymbol(nodeType: .struct)
        
        classSymbol.symbolFilePath = self.sourceFile
        classSymbol.ASTNode = node
        classSymbol.parent = parentStack.last
        classSymbol.originalSymbol = node.name.text
        classSymbol.identifier = node.name.text
        classSymbol.inheritedType = node.inheritanceClause?.inheritedTypes.compactMap({ $0.as(IdentifierTypeSyntax.self)?.name.text })
        node.modifiers.forEach { modifier in
            classSymbol.accessControl = modifier.accessControl
            classSymbol.isFinal = modifier.isFinal
        }
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(classSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        parentStack.append(classSymbol)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: StructDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let classSymbol: SwiftSourceClassSymbol = SwiftSourceClassSymbol(nodeType: .protocol)
        
        classSymbol.symbolFilePath = self.sourceFile
        classSymbol.ASTNode = node
        classSymbol.parent = parentStack.last
        classSymbol.originalSymbol = node.name.text
        classSymbol.identifier = node.name.text
        classSymbol.inheritedType = node.inheritanceClause?.inheritedTypes.compactMap({ $0.as(IdentifierTypeSyntax.self)?.name.text })
        node.modifiers.forEach { modifier in
            classSymbol.accessControl = modifier.accessControl
            classSymbol.isFinal = modifier.isFinal
        }
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(classSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        parentStack.append(classSymbol)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ProtocolDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let funcSymbol: SwiftSourceFunctionSymbol = SwiftSourceFunctionSymbol(nodeType: .function)
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
        
        funcSymbol.returnType = node.signature.returnClause?.trimmedDescription ?? "Void"
        funcSymbol.isMember = SwiftConfusedHelper.isMemberVariable(node)
        funcSymbol.identifier = "\(funcSymbol.isStatic ? "static " : "")\(node.name.text)\(node.signature.trimmedDescription)"
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(funcSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        parentStack.append(funcSymbol)
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let variableSymbol: SwiftSourceSymbol = SwiftSourceSymbol(nodeType: .variable)
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
        node.bindings.forEach { patternBinding in
            if let identPatternBinding: IdentifierPatternSyntax = patternBinding.pattern.as(IdentifierPatternSyntax.self) {
                variableSymbol.originalSymbol = identPatternBinding.identifier.text
            }
            
            if let typeAnnontation: TypeAnnotationSyntax = patternBinding.typeAnnotation {
                variableSymbol.symbolType = typeAnnontation.type.trimmedDescription
            }
        }
        variableSymbol.isMember = SwiftConfusedHelper.isMemberVariable(node)
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope()
    }
}
