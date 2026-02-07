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
        
        funcSymbol.isMember = SwiftConfusedHelper.isMemberVariable(node)
        
        // symbol|static|return|parameter
        var funcSignature: String = "\(node.name.text)|\(funcSymbol.isStatic ? "static" : "")|\(funcSymbol.returnType)|("
        var isFirstParameter: Bool = true
        node.signature.parameterClause.parameters.forEach { parameterSyntax in
            let funcLabel: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .label)
            funcLabel.ASTNode = parameterSyntax
            funcLabel.parent = parentStack.last
            funcLabel.originalSymbol = parameterSyntax.firstName.text
            funcLabel.symbolFilePath = self.sourceFile
            funcSymbol.labels.append(funcLabel)
            
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
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(funcSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        parentStack.last?.children.append(funcSymbol)
        parentStack.append(funcSymbol)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        parentStack.removeLast()
        SwiftSourceScopeManager.sharedManager.popScope()
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
        node.bindings.forEach { patternBinding in
            if let identPatternBinding: IdentifierPatternSyntax = patternBinding.pattern.as(IdentifierPatternSyntax.self) {
                variableSymbol.originalSymbol = identPatternBinding.identifier.text
            }
            
            if let typeAnnontation: TypeAnnotationSyntax = patternBinding.typeAnnotation {
                variableSymbol.symbolType = typeAnnontation.type.trimmedDescription
            } else if let initializer: InitializerClauseSyntax = patternBinding.initializer?.as(InitializerClauseSyntax.self) {
                variableSymbol.symbolType = SwiftConfusedHelper.inferExprSyntaxType(initializer.value)
            }
        }
        variableSymbol.isMember = SwiftConfusedHelper.isMemberVariable(node)
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        parentStack.last?.children.append(variableSymbol)
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
        let variableInfo: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
        variableInfo.symbolFilePath = self.sourceFile
        variableInfo.ASTNode = node
        variableInfo.parent = parentStack.last
        variableInfo.symbolFilePath = self.sourceFile
        
        if let secondName = node.secondName {
            variableInfo.originalSymbol = secondName.text
        } else {
            variableInfo.originalSymbol = node.firstName.text
        }
        
        if let type: IdentifierTypeSyntax = node.type.as(IdentifierTypeSyntax.self) {
            variableInfo.symbolType = type.name.text
        }
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableInfo)
        return super.visit(node)
    }
    
    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        node.conditions.forEach { condSyntax in
            if let optBindingCondSyntax: OptionalBindingConditionSyntax = condSyntax.condition.as(OptionalBindingConditionSyntax.self),
               let identPatternSyntax: IdentifierPatternSyntax = optBindingCondSyntax.pattern.as(IdentifierPatternSyntax.self) {
                
                let variableInfo: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
                variableInfo.symbolFilePath = self.sourceFile
                variableInfo.ASTNode = identPatternSyntax
                variableInfo.parent = parentStack.last
                variableInfo.symbolFilePath = self.sourceFile
                
                variableInfo.originalSymbol = identPatternSyntax.identifier.text
                if let typeAnnotation = optBindingCondSyntax.typeAnnotation,
                   let idPatternSyntax: IdentifierPatternSyntax = typeAnnotation.type.as(IdentifierPatternSyntax.self) {
                    variableInfo.symbolType = idPatternSyntax.identifier.text
                }
                
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableInfo)
            }
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: GuardStmtSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        node.conditions.forEach { condSyntax in
            if let optBindingCondSyntax: OptionalBindingConditionSyntax = condSyntax.condition.as(OptionalBindingConditionSyntax.self),
               let idPatternSyntax: IdentifierPatternSyntax = optBindingCondSyntax.pattern.as(IdentifierPatternSyntax.self) {
                let variableInfo: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
                
                variableInfo.originalSymbol = idPatternSyntax.identifier.text
                variableInfo.symbolFilePath = self.sourceFile
                variableInfo.ASTNode = idPatternSyntax
                variableInfo.parent = parentStack.last
                variableInfo.symbolFilePath = self.sourceFile
                
                if let typeAnnSyntax: TypeAnnotationSyntax = optBindingCondSyntax.typeAnnotation,
                   let idPatternSyntax: IdentifierPatternSyntax = typeAnnSyntax.type.as(IdentifierPatternSyntax.self) {
                    variableInfo.symbolType = idPatternSyntax.identifier.text
                }
                
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableInfo)
            }
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: WhileStmtSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        if let identifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self) {
            
            let variableInfo: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
            variableInfo.symbolFilePath = self.sourceFile
            variableInfo.originalSymbol = identifierPatternSyntax.identifier.text
            variableInfo.ASTNode = identifierPatternSyntax
            variableInfo.parent = parentStack.last
            
            SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableInfo)
        }
        
        return super.visit(node)
    }
    
    override func visitPost(_ node: ForStmtSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        if let captureClause: ClosureCaptureClauseSyntax = node.signature?.capture?.as(ClosureCaptureClauseSyntax.self) {
            captureClause.items.forEach { captureSyntax in
                let variableInfo: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
                variableInfo.originalSymbol = captureSyntax.name.text
                variableInfo.symbolFilePath = self.sourceFile
                variableInfo.ASTNode = captureSyntax
                variableInfo.parent = parentStack.last
                variableInfo.symbolFilePath = self.sourceFile
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableInfo)
            }
        }
        
        if let paramClause: ClosureShorthandParameterListSyntax = node.signature?.parameterClause?.as(ClosureShorthandParameterListSyntax.self) {
            paramClause.forEach { parameterSyntax in
                let variableInfo: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
                variableInfo.originalSymbol = parameterSyntax.name.text
                variableInfo.symbolFilePath = self.sourceFile
                variableInfo.ASTNode = parameterSyntax
                variableInfo.parent = parentStack.last
                variableInfo.symbolFilePath = self.sourceFile
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableInfo)
            }
        } else if let paramClause: ClosureParameterClauseSyntax = node.signature?.parameterClause?.as(ClosureParameterClauseSyntax.self) {
            paramClause.parameters.forEach { parameterSyntax in
                let variableInfo: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
                variableInfo.symbolFilePath = self.sourceFile
                variableInfo.ASTNode = parameterSyntax
                variableInfo.parent = parentStack.last
                variableInfo.symbolFilePath = self.sourceFile
                if let secondName = parameterSyntax.secondName {
                    variableInfo.originalSymbol = secondName.text
                } else {
                    variableInfo.originalSymbol = parameterSyntax.firstName.text
                }
                
                if let type: IdentifierTypeSyntax = parameterSyntax.type?.as(IdentifierTypeSyntax.self) {
                    variableInfo.symbolType = type.name.text
                }
                
                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(variableInfo)
            }
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let enumInfo: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .enum)
        
        enumInfo.originalSymbol = node.name.text
        enumInfo.symbolFilePath = self.sourceFile
        enumInfo.isMember = SwiftConfusedHelper.isMemberVariable(node)
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
            enumCaseInfo.isMember = SwiftConfusedHelper.isMemberVariable(node)
            enumCaseInfo.ASTNode = enumCaseElemSyntax
            enumCaseElemSyntax.parameterClause?.parameters.forEach { enumCaseParamDecl in
                if let identTypeSyntax: IdentifierTypeSyntax = enumCaseParamDecl.type.as(IdentifierTypeSyntax.self) {
                    enumCaseInfo.relatedType.append(identTypeSyntax.name.text)
                }
            }
            
            enumCaseInfo.parent = parentStack.last
            SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(enumCaseInfo)
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: DoStmtSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: SwitchCaseSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope()
    }
}
