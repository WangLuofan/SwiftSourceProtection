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
            symbol.parent = self.parentStack.last
        }
        
        self.parentStack.append(symbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        SwiftSourceScopeManager.sharedManager.popScope(false)
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SwiftSourceSymbol = node.symbol(.class, self.sourceFile)
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        
        if !self.parentStack.isEmpty {
            symbol.parent = self.parentStack.last
        }
        
        self.parentStack.append(symbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: ProtocolDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        SwiftSourceScopeManager.sharedManager.popScope(false)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SwiftSourceClassSymbol = node.symbol(.enum, self.sourceFile)
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        
        if !self.parentStack.isEmpty {
            symbol.parent = self.parentStack.last
        }
        
        if let clsSymbol: SwiftSourceClassSymbol = self.parentStack.last as? SwiftSourceClassSymbol {
            clsSymbol.members.append(symbol)
        }
        
        self.parentStack.append(symbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: EnumDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        SwiftSourceScopeManager.sharedManager.popScope(false)
    }
    
    override func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SwiftSourceEnumCaseSymbol = SwiftSourceEnumCaseSymbol(nodeKind: .enumCase)
        symbol.originalSymbol = node.name.text
        symbol.ASTNode = node
        symbol.parent = self.parentStack.last
        
        if let type = self.parentStack.last?.symbolType {
            symbol.symbolType = type
        }
        
        node.parameterClause?.parameters.forEach { enumCaseParamSyntax in
            symbol.associatedType.append(SwiftConfusedHelper.detectTypeSyntax(enumCaseParamSyntax.type))
        }
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        return super.visit(node)
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        let symbol: SwiftSourceSymbol = node.symbol(.class, self.sourceFile)
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        
        if !self.parentStack.isEmpty {
            symbol.parent = self.parentStack.last
        }
        
        self.parentStack.append(symbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: StructDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
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
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        SwiftSourceScopeManager.sharedManager.popScope(false)
    }
    
    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        let varSymbol: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
        if let idPattern: IdentifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self) {
            varSymbol.originalSymbol = idPattern.identifier.text
        }
        
        if let typeAnnotation = node.typeAnnotation {
            varSymbol.symbolType = SwiftConfusedHelper.detectTypeSyntax(typeAnnotation.type)
        } else {
            let seqType: SwiftSymbolType = SwiftConfusedHelper.inferExprSyntaxType(node.sequence)
            if let arrType: SwiftSymbolArrayType = seqType as? SwiftSymbolArrayType {
                varSymbol.symbolType = arrType.elementType
            } else if let dicType: SwiftSymbolDictionaryType = seqType as? SwiftSymbolDictionaryType {
                varSymbol.symbolType = SwiftSymbolTupleType(elements: [dicType.keyType, dicType.valueType])
            }
        }
        
        varSymbol.symbolFilePath = self.sourceFile
        
        if !self.parentStack.isEmpty {
            varSymbol.parent = self.parentStack.last
        }
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(varSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: ForStmtSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        SwiftSourceScopeManager.sharedManager.popScope(false)
    }
    
    override func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
        let varSymbol: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
        if let idPattern: IdentifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self) {
            varSymbol.originalSymbol = idPattern.identifier.text
        }
        varSymbol.symbolFilePath = self.sourceFile
        if let typeAnnotation = node.typeAnnotation {
            varSymbol.symbolType = SwiftConfusedHelper.detectTypeSyntax(typeAnnotation.type)
        } else if let initializer = node.initializer {
            varSymbol.symbolType = SwiftConfusedHelper.inferExprSyntaxType(initializer.value)
        }
        
        if !self.parentStack.isEmpty {
            varSymbol.parent = self.parentStack.last
        }
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(varSymbol)
        return super.visit(node)
    }
    
    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        let funcSymbol = node.symbol(self.sourceFile)
        if !self.parentStack.isEmpty {
            funcSymbol.parent = self.parentStack.last
        }
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(funcSymbol)
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: InitializerDeclSyntax) {
        if !self.parentStack.isEmpty {
            self.parentStack.removeLast()
        }
        
        SwiftSourceScopeManager.sharedManager.popScope()
    }
    
    override func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        return super.visit(node)
    }
    
    override func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
        return super.visit(node)
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
        
        SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(symbol)
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        SwiftSourceScopeManager.sharedManager.pushScope()
        return super.visit(node)
    }
    
    override func visitPost(_ node: ClosureExprSyntax) {
        SwiftSourceScopeManager.sharedManager.popScope(false)
    }
}
