//
//  SwiftSourceCollection.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/12/12.
//

import SwiftSyntax
import SwiftParser

class SwiftSourceCollection: SyntaxVisitor {
    private let sourceFile: String
    private let sourceInfo: SwiftSourceInfo
    
    init(sourceFile: String, sourceInfo: SwiftSourceInfo) {
        self.sourceFile = sourceFile
        self.sourceInfo = sourceInfo
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        let classInfo: SwiftSourceClassInfo = SwiftSourceClassInfo()
        classInfo.filePath = self.sourceFile
        
        classInfo.name = node.name.text
        node.modifiers.forEach { modifer in
            classInfo.accessControl = modifer.accessControl
            classInfo.isFinal = modifer.isFinal
        }
        
        if let inheritanceClause = node.inheritanceClause {
            inheritanceClause.inheritedTypes.forEach { inheritedType in
                classInfo.superClasses.append(inheritedType.type.trimmedDescription)
            }
        }
        
        self.sourceInfo.appendSourceInfo(classInfo)
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        self.sourceInfo.popSourceInfo()
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let functionInfo: SwiftSourceFunctionInfo = SwiftSourceFunctionInfo()
        
        functionInfo.name = node.name.text
        functionInfo.filePath = self.sourceFile
        node.modifiers.forEach { modifier in
            functionInfo.accessControl = modifier.accessControl
            functionInfo.isStatic = modifier.isStatic
            functionInfo.isFinal = modifier.isFinal
            functionInfo.isClass = modifier.isClass
            functionInfo.isOverride = modifier.isOverride
        }
        functionInfo.signature = node.signature.trimmedDescription
        let retType = node.signature.returnClause?.type.trimmedDescription
        
        if retType != "Void" {
            functionInfo.returnType = retType
        }
        
        self.sourceInfo.appendSourceInfo(functionInfo)
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        self.sourceInfo.popSourceInfo()
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        let variableInfo: SwiftSourceVariableInfo = SwiftSourceVariableInfo(SwiftConfuseHelper.isMemberVariable(node))
        variableInfo.filePath = self.sourceFile
        
        node.bindings.forEach { binding in
            let pattern = binding.pattern
            if let identifierPatternSyntax = pattern.as(IdentifierPatternSyntax.self) {
                variableInfo.name = identifierPatternSyntax.identifier.text
            }
            
            if let retType = binding.typeAnnotation?.type.trimmedDescription, retType != "Void" {
                variableInfo.type = retType
            }
        }
        
        node.modifiers.forEach { modifier in
            variableInfo.isStatic = modifier.isStatic
            variableInfo.isClass = modifier.isClass
            variableInfo.isOverride = modifier.isOverride
            variableInfo.accessControl = modifier.accessControl
            variableInfo.isFinal = modifier.isFinal
        }
        
        self.sourceInfo.appendSourceInfo(variableInfo)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
        self.sourceInfo.popSourceInfo()
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let protocolInfo: SwiftSourceProtocolInfo = SwiftSourceProtocolInfo()
        protocolInfo.filePath = self.sourceFile
        
        protocolInfo.name = node.name.text
        node.modifiers.forEach { modifer in
            protocolInfo.accessControl = modifer.accessControl
            protocolInfo.isFinal = modifer.isFinal
        }
        
        if let inheritanceClause = node.inheritanceClause {
            inheritanceClause.inheritedTypes.forEach { inheritedType in
                protocolInfo.superClasses.append(inheritedType.type.description)
            }
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ProtocolDeclSyntax) {
        self.sourceInfo.popSourceInfo()
    }
}
