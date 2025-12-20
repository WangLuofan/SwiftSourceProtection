//
//  SwiftSourceCollection.swift
//  SwiftRefactorUtil
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
                classInfo.superClasses.append(inheritedType.type.description)
            }
        }
        
        SwiftSourceInfo.shared.appendSourceInfo(classInfo)
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        SwiftSourceInfo.shared.popSourceInfo()
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let functionInfo: SwiftSourceFunctionInfo = SwiftSourceFunctionInfo()
        
        functionInfo.name = node.name.text
        node.modifiers.forEach { modifier in
            functionInfo.accessControl = modifier.accessControl
            functionInfo.isStatic = modifier.isStatic
            functionInfo.isFinal = modifier.isFinal
            functionInfo.isClass = modifier.isClass
            functionInfo.isOverride = modifier.isOverride
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        SwiftSourceInfo.shared.popSourceInfo()
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        if SwiftRefactorHelper.isMemberVariable(node) {
            let propertyInfo: SwiftSourcePropertyInfo = SwiftSourcePropertyInfo()
            propertyInfo.filePath = self.sourceFile
            
            node.bindings.forEach { binding in
                let pattern = binding.pattern
                if let identifierPatternSyntax = pattern.as(IdentifierPatternSyntax.self) {
                    propertyInfo.name = identifierPatternSyntax.identifier.text
                }
            }
            
            node.modifiers.forEach { modifier in
                propertyInfo.isStatic = modifier.isStatic
                propertyInfo.isClass = modifier.isClass
                propertyInfo.isOverride = modifier.isOverride
                propertyInfo.accessControl = modifier.accessControl
                propertyInfo.isFinal = modifier.isFinal
            }
            
            SwiftSourceInfo.shared.appendSourceInfo(propertyInfo)
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
        SwiftSourceInfo.shared.popSourceInfo()
    }
}
