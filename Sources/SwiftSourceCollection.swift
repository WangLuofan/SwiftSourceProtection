//
//  SwiftSourceCollection.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/12/12.
//

import SwiftSyntax
import SwiftParser

nonisolated(unsafe) var parentStack: [SwiftSourceBaseInfo] = [SwiftSourceBaseInfo]()

class SwiftSourceCollection: SyntaxVisitor {
    private let sourceFile: String
    
    init(sourceFile: String) {
        self.sourceFile = sourceFile
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        
        let classInfo: SwiftSourceClassInfo = SwiftSourceClassInfo()
        classInfo.filePath = self.sourceFile
        
        classInfo.identifier = node.name.text
        classInfo.symbolName = node.name.text
        
        node.modifiers.forEach { modifer in
            classInfo.accessControl = modifer.accessControl
            classInfo.isFinal = modifer.isFinal
        }
        
        if let inheritanceClause = node.inheritanceClause {
            inheritanceClause.inheritedTypes.forEach { inheritedType in
                classInfo.superClasses.append(inheritedType.type.trimmedDescription)
            }
        }
        
        SwiftSourceScopeManager.shared.pushSourceInfo(classInfo)
        SwiftSourceScopeManager.shared.pushScope()
        
        classInfo.parent = parentStack.last
        parentStack.append(classInfo)
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.shared.popScope()
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        
        let functionInfo: SwiftSourceFunctionInfo = SwiftSourceFunctionInfo()
        
        functionInfo.symbolName = node.name.text
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
        functionInfo.identifier = "\(functionInfo.symbolName)\(functionInfo.signature ?? "")"
        let retType = node.signature.returnClause?.type.trimmedDescription
        
        if retType != "Void" {
            functionInfo.returnType = retType
        }
        
        SwiftSourceScopeManager.shared.pushSourceInfo(functionInfo)
        SwiftSourceScopeManager.shared.pushScope()
        
        functionInfo.parent = parentStack.last
        parentStack.append(functionInfo)
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.shared.popScope()
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        
        let variableInfo: SwiftSourceVariableInfo = SwiftSourceVariableInfo()
        variableInfo.filePath = self.sourceFile
        variableInfo.isMember = SwiftConfuseHelper.isMemberVariable(node)
        
        node.bindings.forEach { binding in
            let pattern = binding.pattern
            if let identifierPatternSyntax = pattern.as(IdentifierPatternSyntax.self) {
                variableInfo.identifier = identifierPatternSyntax.identifier.text
                variableInfo.symbolName = identifierPatternSyntax.identifier.text
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
        
        SwiftSourceScopeManager.shared.pushSourceInfo(variableInfo)
//        SwiftSourceScopeManager.shared.pushScope()
        
        if variableInfo.isMember {
            variableInfo.parent = parentStack.last
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
//        SwiftSourceScopeManager.shared.popScope()
    }
    
    override func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.shared.pushScope()
        
        node.conditions.forEach { condSyntax in
            if let optBindingCondSyntax: OptionalBindingConditionSyntax = condSyntax.condition.as(OptionalBindingConditionSyntax.self),
               let identPatternSyntax: IdentifierPatternSyntax = optBindingCondSyntax.pattern.as(IdentifierPatternSyntax.self) {
                let variableInfo: SwiftSourceVariableInfo = SwiftSourceVariableInfo()
                
                variableInfo.symbolName = identPatternSyntax.identifier.text
                if let typeAnnotation = optBindingCondSyntax.typeAnnotation,
                   let idPatternSyntax: IdentifierPatternSyntax = typeAnnotation.type.as(IdentifierPatternSyntax.self) {
                    variableInfo.type = idPatternSyntax.identifier.text
                }
                
                SwiftSourceScopeManager.shared.pushSourceInfo(variableInfo)
            }
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: IfExprSyntax) {
        SwiftSourceScopeManager.shared.popScope()
    }

    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        
        let protocolInfo: SwiftSourceClassInfo = SwiftSourceClassInfo(sourcetype: .Protocol)
        protocolInfo.filePath = self.sourceFile
        
        protocolInfo.identifier = node.name.text
        protocolInfo.symbolName = node.name.text
        
        node.modifiers.forEach { modifer in
            protocolInfo.accessControl = modifer.accessControl
            protocolInfo.isFinal = modifer.isFinal
        }
        
        if let inheritanceClause = node.inheritanceClause {
            inheritanceClause.inheritedTypes.forEach { inheritedType in
                protocolInfo.superClasses.append(inheritedType.type.description)
            }
        }
        
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
        
        classInfo.identifier = node.name.text
        classInfo.symbolName = node.name.text
        
        node.modifiers.forEach { modifer in
            classInfo.accessControl = modifer.accessControl
            classInfo.isFinal = modifer.isFinal
        }
        
        if let inheritanceClause = node.inheritanceClause {
            inheritanceClause.inheritedTypes.forEach { inheritedType in
                classInfo.superClasses.append(inheritedType.type.trimmedDescription)
            }
        }
        
        SwiftSourceScopeManager.shared.pushSourceInfo(classInfo)
        SwiftSourceScopeManager.shared.pushScope()
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: StructDeclSyntax) {
        SwiftSourceScopeManager.shared.popScope()
    }
    
    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.shared.pushScope()
        
        if let identifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self) {
            let identifier = identifierPatternSyntax.identifier.text
            
            let variableInfo: SwiftSourceVariableInfo = SwiftSourceVariableInfo()
            variableInfo.filePath = self.sourceFile
            variableInfo.symbolName = identifier
            variableInfo.identifier = identifier
            
            SwiftSourceScopeManager.shared.pushSourceInfo(variableInfo)
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ForStmtSyntax) {
        SwiftSourceScopeManager.shared.popScope()
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        let firstName = node.firstName
        
        let variableInfo: SwiftSourceVariableInfo = SwiftSourceVariableInfo()
        variableInfo.label = firstName.text
        variableInfo.symbolName = firstName.text
        
        if let secondName = node.secondName {
            variableInfo.symbolName = secondName.text
        }
        
        SwiftSourceScopeManager.shared.pushSourceInfo(variableInfo)
        return super.visit(node)
    }
    
    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.shared.pushScope()
        
        node.conditions.forEach { condSyntax in
            if let optBindingCondSyntax: OptionalBindingConditionSyntax = condSyntax.condition.as(OptionalBindingConditionSyntax.self),
               let identPatternSyntax: IdentifierPatternSyntax = optBindingCondSyntax.pattern.as(IdentifierPatternSyntax.self) {
                let variableInfo: SwiftSourceVariableInfo = SwiftSourceVariableInfo()
                
                variableInfo.symbolName = identPatternSyntax.identifier.text
                if let typeAnnotation = optBindingCondSyntax.typeAnnotation,
                   let idPatternSyntax: IdentifierPatternSyntax = typeAnnotation.type.as(IdentifierPatternSyntax.self) {
                    variableInfo.type = idPatternSyntax.identifier.text
                }
                
                SwiftSourceScopeManager.shared.pushSourceInfo(variableInfo)
            }
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: GuardStmtSyntax) {
        SwiftSourceScopeManager.shared.popScope()
    }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        return super.visit(node)
    }
    
    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        return super.visit(node)
    }
}
