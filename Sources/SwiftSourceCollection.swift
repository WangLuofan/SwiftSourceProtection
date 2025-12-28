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
    
    init(sourceFile: String) {
        self.sourceFile = sourceFile
        
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
        
        print("++++++++++++\(classInfo.name)")
        
        SwiftSourceScopeManager.shared.pushSourceInfo(classInfo)
        SwiftSourceScopeManager.shared.pushScope()
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        SwiftSourceScopeManager.shared.popScope()
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        
        let functionInfo: SwiftSourceFunctionInfo = SwiftSourceFunctionInfo()
        
        functionInfo.functionName = node.name.text
        functionInfo.filePath = self.sourceFile
        functionInfo.isMember = SwiftConfuseHelper.isMemberVariable(node)
        
        node.modifiers.forEach { modifier in
            functionInfo.accessControl = modifier.accessControl
            functionInfo.isStatic = modifier.isStatic
            functionInfo.isFinal = modifier.isFinal
            functionInfo.isClass = modifier.isClass
            functionInfo.isOverride = modifier.isOverride
        }
        functionInfo.signature = node.signature.trimmedDescription
        functionInfo.name = "\(functionInfo.functionName ?? "")\(functionInfo.signature ?? "")"
        let retType = node.signature.returnClause?.type.trimmedDescription
        
        if retType != "Void" {
            functionInfo.returnType = retType
        }
        
        print("++++++++++++\(functionInfo.name)")

        SwiftSourceScopeManager.shared.pushSourceInfo(functionInfo)
        SwiftSourceScopeManager.shared.pushScope()
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        SwiftSourceScopeManager.shared.popScope()
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        
        let variableInfo: SwiftSourceVariableInfo = SwiftSourceVariableInfo()
        variableInfo.filePath = self.sourceFile
        variableInfo.isMember = SwiftConfuseHelper.isMemberVariable(node)
        
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
        
        print("++++++++++++\(variableInfo.name)")

        SwiftSourceScopeManager.shared.pushSourceInfo(variableInfo)
        SwiftSourceScopeManager.shared.pushScope()
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
        SwiftSourceScopeManager.shared.popScope()
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
        
        print("++++++++++++\(protocolInfo.name)")

        SwiftSourceScopeManager.shared.pushSourceInfo(protocolInfo)
        SwiftSourceScopeManager.shared.pushScope()
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ProtocolDeclSyntax) {
        SwiftSourceScopeManager.shared.popScope()
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
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
        
        print("++++++++++++\(classInfo.name)")

        SwiftSourceScopeManager.shared.pushSourceInfo(classInfo)
        SwiftSourceScopeManager.shared.pushScope()
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: StructDeclSyntax) {
        SwiftSourceScopeManager.shared.popScope()
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        return super.visit(node)
    }
    
    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        return super.visit(node)
    }
}
