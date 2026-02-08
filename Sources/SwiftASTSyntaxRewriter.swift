//
//  SwiftASTSyntaxRewriter.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/2/6.
//

import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

class SwiftASTSyntaxRewriter: SyntaxRewriter {
    private let projectPath: String
    
    init(projectPath: String) {
        self.projectPath = projectPath
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let clsName: String = node.name.text
        
        guard let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsName) as? SwiftSourceClassSymbol,
              let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol) else {
            return super.visit(node)
        }
        
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        let clsName: String = node.name.text
        
        guard let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsName) as? SwiftSourceClassSymbol,
              let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol) else {
            return super.visit(node)
        }
        
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
    
//    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
//        guard let extendedType = node.extendedType.as(IdentifierTypeSyntax.self),
//              let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(extendedType.name.text) as? SwiftSourceClassSymbol,
//              let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol) else {
//            return super.visit(node)
//        }
//        
//        let newNode = node.with(\.extendedType,
//                                 TypeSyntax(IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: confusedSymbolName)))
//            .with(\.leadingTrivia, node.extendedType.leadingTrivia)
//            .with(\.trailingTrivia, node.extendedType.trailingTrivia))
//            .with(\.leadingTrivia, node.leadingTrivia)
//            .with(\.trailingTrivia, node.trailingTrivia)
//        
//        return super.visit(newNode)
//    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        if let funcSymbol: SwiftSourceFunctionSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(node.name.text) as? SwiftSourceFunctionSymbol,
           let confusedFuncSymbol: String = SwiftConfusedHelper.confusedSymbol(funcSymbol) {
            newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedFuncSymbol)
                .with(\.leadingTrivia, node.name.leadingTrivia)
                .with(\.trailingTrivia, node.name.trailingTrivia))
        }
        
        SwiftSourceScopeManager.sharedManager.pushScope()

        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
        var newNode = node
        
        var varSymbol: SwiftSourceSymbol?
        if let secondName = node.secondName?.text {
            varSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(secondName)
        } else {
            varSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(node.firstName.text)
        }
        
        if let varSymbol,
           let funcSymbol: SwiftSourceFunctionSymbol = varSymbol.parent as? SwiftSourceFunctionSymbol {
            if let secondName = node.secondName {
                if let confusedSecondName: String = SwiftConfusedHelper.confusedSymbol(varSymbol) {
                    newNode = node.with(\.secondName, TokenSyntax(stringLiteral: confusedSecondName)
                        .with(\.leadingTrivia, secondName.leadingTrivia)
                        .with(\.trailingTrivia, secondName.trailingTrivia))
                }
            } else if let labelSymbol: SwiftSourceSymbol = funcSymbol.labels[node.firstName.text] {
                if let confusedLabelSymbolName: String = labelSymbol.confusedSymbol {
                    newNode = newNode.with(\.firstName, TokenSyntax(stringLiteral: confusedLabelSymbolName)
                        .with(\.leadingTrivia, node.firstName.leadingTrivia)
                        .with(\.trailingTrivia, node.firstName.trailingTrivia))
                }
            }
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        var newBindings: [PatternBindingSyntax] = [PatternBindingSyntax]()
        node.bindings.forEach { binding in
            if let patternBinding: IdentifierPatternSyntax = binding.pattern.as(IdentifierPatternSyntax.self),
               let symbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(patternBinding.identifier.text),
               let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(symbol) {
                let newPattern: IdentifierPatternSyntax = IdentifierPatternSyntax(identifier: TokenSyntax(stringLiteral: confusedSymbolName)
                    .with(\.leadingTrivia, patternBinding.identifier.leadingTrivia)
                    .with(\.trailingTrivia, patternBinding.identifier.trailingTrivia)
                )
                
                if let newPattern: PatternSyntax = PatternSyntax(newPattern) {
                    var newBinding = binding.with(\.pattern, newPattern).with(\.leadingTrivia, patternBinding.leadingTrivia).with(\.trailingTrivia, patternBinding.trailingTrivia)
                    
                    if let typeAnnotation: TypeAnnotationSyntax = binding.typeAnnotation,
                       let typeName: String = typeAnnotation.type.as(IdentifierTypeSyntax.self)?.name.text,
                       let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(typeName),
                       let confusedTypeName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol) {
                        let confusedTypeAnnotaton: TypeAnnotationSyntax = TypeAnnotationSyntax(
                            type: IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: confusedTypeName)
                            .with(\.leadingTrivia, typeAnnotation.type.leadingTrivia)
                            .with(\.trailingTrivia, typeAnnotation.type.trailingTrivia)))
                            .with(\.leadingTrivia, typeAnnotation.leadingTrivia)
                            .with(\.trailingTrivia, typeAnnotation.trailingTrivia)
                        
                        newBinding = newBinding.with(\.typeAnnotation, confusedTypeAnnotaton)
                            .with(\.leadingTrivia, binding.leadingTrivia)
                            .with(\.trailingTrivia, binding.trailingTrivia)
                    }
                    
                    newBindings.append(newBinding)
                    return
                }
                
                newBindings.append(binding)
            }
        }
        
        SwiftSourceScopeManager.sharedManager.pushScope()
        
        newNode = node.with(\.bindings, PatternBindingListSyntax(newBindings)
            .with(\.leadingTrivia, node.bindings.leadingTrivia)
            .with(\.trailingTrivia, node.bindings.trailingTrivia))
        
        return super.visit(newNode)
    }
    
    override func visitPost(_ node: Syntax) {
        if let _ = node.as(ClassDeclSyntax.self) {
            SwiftSourceScopeManager.sharedManager.popScope(true)
        } else if let _ = node.as(FunctionDeclSyntax.self) {
            SwiftSourceScopeManager.sharedManager.popScope(true)
        } else if let _ = node.as(VariableDeclSyntax.self) {
            SwiftSourceScopeManager.sharedManager.popScope(true)
        } else if let _ = node.as(StructDeclSyntax.self) {
            SwiftSourceScopeManager.sharedManager.popScope(true)
        }
    }
}
