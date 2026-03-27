
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
    private let sourceFile: String
    
    init(sourceFile: String) {
        self.sourceFile = sourceFile
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        
        guard let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(node, inFile: self.sourceFile)
                as? SwiftSourceClassSymbol else {
            return super.visit(node)
        }
        
        let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol)
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        
        guard let proSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(node, inFile: self.sourceFile)
                as? SwiftSourceClassSymbol else {
            return super.visit(node)
        }
        
        let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(proSymbol)
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        
        guard let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(node, inFile: self.sourceFile)
                as? SwiftSourceClassSymbol else {
            return super.visit(node)
        }
        
        let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol)
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        if let extendedType = node.extendedType.as(IdentifierTypeSyntax.self) {
            if let clsSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(extendedType.name.text) as? SwiftSourceClassSymbol {
                
                let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(clsSymbol)
                let newNode = node.with(\.extendedType,
                                         TypeSyntax(IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: confusedSymbolName)))
                    .with(\.leadingTrivia, node.extendedType.leadingTrivia)
                    .with(\.trailingTrivia, node.extendedType.trailingTrivia))
                    .with(\.leadingTrivia, node.leadingTrivia)
                    .with(\.trailingTrivia, node.trailingTrivia)
                
                return super.visit(newNode)
            }
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        guard let enumSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(node, inFile: self.sourceFile)
                as? SwiftSourceClassSymbol else {
            return super.visit(node)
        }
        
        let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(enumSymbol)
        let newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
            .with(\.leadingTrivia, node.name.leadingTrivia)
            .with(\.trailingTrivia, node.name.trailingTrivia))
        
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        if let funcSymbol: SwiftSourceFunctionSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(node, inFile: self.sourceFile) as? SwiftSourceFunctionSymbol {
            let confusedFuncSymbol: String = SwiftConfusedHelper.confusedSymbol(funcSymbol)
            newNode = node.with(\.name, TokenSyntax(stringLiteral: confusedFuncSymbol)
                .with(\.leadingTrivia, node.name.leadingTrivia)
                .with(\.trailingTrivia, node.name.trailingTrivia))
            
            if let returnClause: ReturnClauseSyntax = node.signature.returnClause {
                if let idTypeSyntax: IdentifierTypeSyntax = returnClause.type.as(IdentifierTypeSyntax.self),
                   let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(idTypeSyntax.name.text) {
                    let confusedSymbol = SwiftConfusedHelper.confusedSymbol(typeSymbol)
                    newNode = newNode.with(\.signature, newNode.signature
                        .with(\.returnClause, returnClause
                            .with(\.type, TypeSyntax(idTypeSyntax
                                .with(\.name, TokenSyntax(stringLiteral: confusedSymbol)
                                    .with(\.leadingTrivia, idTypeSyntax.name.leadingTrivia)
                                    .with(\.trailingTrivia, idTypeSyntax.name.trailingTrivia)))
                            )
                        )
                    )
                }
            }
        }
        
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        var newNode = node

        var confusedBindings: [PatternBindingSyntax] = [PatternBindingSyntax]()
        node.bindings.forEach { patternBindingSyntax in
            var confusedBinding = patternBindingSyntax
            if let idPatternSyntax: IdentifierPatternSyntax = patternBindingSyntax.pattern.as(IdentifierPatternSyntax.self) {
                let variableSymbol: SwiftSourceSymbol? = SwiftSourceScopeManager.sharedManager.findSymbol(node, inFile: self.sourceFile)
                if let variableSymbol {
                    let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(variableSymbol)
                    let confusedPattern = idPatternSyntax
                        .with(\.identifier, TokenSyntax(stringLiteral: confusedSymbolName)
                            .with(\.leadingTrivia, idPatternSyntax.identifier.leadingTrivia)
                            .with(\.trailingTrivia, idPatternSyntax.identifier.trailingTrivia)
                        )
                    
                    confusedBinding = patternBindingSyntax
                        .with(\.pattern, PatternSyntax(confusedPattern
                            .with(\.leadingTrivia, patternBindingSyntax.pattern.leadingTrivia)
                            .with(\.trailingTrivia, patternBindingSyntax.pattern.trailingTrivia)
                        ))
                }
            }
            
            confusedBindings.append(confusedBinding)
        }

        newNode = node
            .with(\.bindings, PatternBindingListSyntax(confusedBindings)
                .with(\.leadingTrivia, node.bindings.leadingTrivia)
                .with(\.trailingTrivia, node.bindings.trailingTrivia))

        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: TypeAnnotationSyntax) -> TypeAnnotationSyntax {
        var newNode = node
        
        if let idTypeSyntax: IdentifierTypeSyntax = node.type.as(IdentifierTypeSyntax.self),
           let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(idTypeSyntax.name.text) {
            let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol)
            
            newNode = newNode.with(\.type, TypeSyntax(idTypeSyntax
                .with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
                    .with(\.leadingTrivia, idTypeSyntax.name.leadingTrivia)
                    .with(\.trailingTrivia, idTypeSyntax.name.trailingTrivia)
                )
            ))
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: DoStmtSyntax) -> StmtSyntax {
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: IfExprSyntax) -> ExprSyntax {
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(node)
    }
    
    override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
        var newNode = node
        return super.visit(newNode)
    }
    
    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        var newNode = node
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        return super.visit(newNode)
    }
    
    override func visit(_ node: IdentifierPatternSyntax) -> PatternSyntax {
        var newNode = node
        
        if let varSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(node.identifier.text) {
            let confusedSymbol = SwiftConfusedHelper.confusedSymbol(varSymbol)
            newNode = newNode.with(\.identifier, TokenSyntax(stringLiteral: confusedSymbol)
                .with(\.leadingTrivia, node.identifier.leadingTrivia)
                .with(\.trailingTrivia, node.identifier.trailingTrivia)
            )
        }
        
        return super.visit(newNode)
    }
    
//    override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
//        var newNode = node
//        let refName: String = node.baseName.text
//        
//        if refName.isSwiftKeyWord {
//            return super.visit(newNode)
//        }
//        
//        var clsSymbol: SwiftSourceClassSymbol?
//        var referenceSymbol: SwiftSourceSymbol?
//        
//        if let refSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(refName) {
//            referenceSymbol = refSymbol
//        } else if let clsDecl: ClassDeclSyntax = SwiftConfusedHelper.findNodeParent(node, .classDecl)?.as(ClassDeclSyntax.self) {
//            clsSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsDecl.name.text) as? SwiftSourceClassSymbol
//        } else if let clsDecl: ExtensionDeclSyntax = SwiftConfusedHelper.findNodeParent(node, .extensionDecl)?.as(ExtensionDeclSyntax.self) {
//            clsSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsDecl.name.text) as? SwiftSourceClassSymbol
//        } else if let clsDecl: StructDeclSyntax = SwiftConfusedHelper.findNodeParent(node, .structDecl)?.as(StructDeclSyntax.self) {
//            clsSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsDecl.name.text) as? SwiftSourceClassSymbol
//        } else if let clsDecl: ProtocolDeclSyntax = SwiftConfusedHelper.findNodeParent(node, .protocolDecl)?.as(ProtocolDeclSyntax.self) {
//            clsSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsDecl.name.text) as? SwiftSourceClassSymbol
//        } else if let clsDecl: EnumDeclSyntax = SwiftConfusedHelper.findNodeParent(node, .enumDecl)?.as(EnumDeclSyntax.self) {
//            clsSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsDecl.name.text) as? SwiftSourceClassSymbol
//        }
//        
//        if let clsSymbol {
//            if node.baseName.text == clsSymbol.originalSymbol {
//                referenceSymbol = clsSymbol
//            } else {
//                referenceSymbol = SwiftConfusedHelper.findChildSymbol(clsSymbol, node.baseName.text)
//            }
//        }
//        
//        if let referenceSymbol {
//            let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(referenceSymbol)
//            newNode = node.with(\.baseName, TokenSyntax(stringLiteral: confusedSymbolName)
//                .with(\.leadingTrivia, node.baseName.leadingTrivia)
//                .with(\.trailingTrivia, node.baseName.trailingTrivia)
//            )
//        }
//        
//        return super.visit(newNode)
//    }
//
//    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
//        var newNode = node
//        
//        var paramSymbol: SwiftSourceSymbol?
//        if let funcSymbol: SwiftSourceFunctionSymbol = parentStack.last as? SwiftSourceFunctionSymbol {
//            if let secondName = node.secondName {
//                
//                let secondParamSymbol: SwiftSourceSymbol = node.funcParameterSymbol(self.sourceFile)
//                SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(secondParamSymbol)
//                
//                let confusedSecondName: String = SwiftConfusedHelper.confusedSymbol(secondParamSymbol)
//                newNode = newNode.with(\.secondName, TokenSyntax(stringLiteral: confusedSecondName)
//                    .with(\.leadingTrivia, secondName.leadingTrivia)
//                    .with(\.trailingTrivia, secondName.trailingTrivia)
//                )
//                
//                paramSymbol = secondParamSymbol
//            }
//            
//            for labelSymbol in funcSymbol.labels {
//                if labelSymbol.originalSymbol != node.firstName.text {
//                    continue
//                }
//                
//                if let confusedLabelSymbolName: String = labelSymbol.confusedSymbol {
//                    newNode = newNode.with(\.firstName, TokenSyntax(stringLiteral: confusedLabelSymbolName)
//                        .with(\.leadingTrivia, node.firstName.leadingTrivia)
//                        .with(\.leadingTrivia, node.firstName.leadingTrivia)
//                        .with(\.trailingTrivia, node.firstName.trailingTrivia))
//                }
//                
//                if node.secondName == nil {
//                    paramSymbol = labelSymbol
//                }
//            }
//        }
//        
//        paramSymbol?.symbolType = node.type.trimmedDescription
//        
//        if let paramSymbol {
//            SwiftSourceScopeManager.sharedManager.currentScope?.pushSymbol(paramSymbol)
//        }
//        
//        return super.visit(newNode)
//    }
    
    override func visit(_ node: OptionalBindingConditionSyntax) -> OptionalBindingConditionSyntax {
        var newNode = node
        if let idPattern: IdentifierPatternSyntax = node.pattern.as(IdentifierPatternSyntax.self),
           let varSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(idPattern.identifier.text) {
            let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(varSymbol)
            newNode = node.with(\.pattern, PatternSyntax(idPattern
                .with(\.identifier, TokenSyntax(stringLiteral: confusedSymbolName)
                    .with(\.leadingTrivia, idPattern.identifier.leadingTrivia)
                    .with(\.trailingTrivia, idPattern.identifier.trailingTrivia)
                )
            ))
        }
        
        if let type: IdentifierTypeSyntax = node.typeAnnotation?.as(IdentifierTypeSyntax.self),
           let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(type.name.text) {
            let confusedTypeSymbol: String = SwiftConfusedHelper.confusedSymbol(typeSymbol)
            newNode = node.with(\.typeAnnotation, node.typeAnnotation?
                .with(\.type, TypeSyntax(type.with(\.name, TokenSyntax(stringLiteral: confusedTypeSymbol)
                    .with(\.leadingTrivia, type.name.leadingTrivia)
                    .with(\.trailingTrivia, type.name.trailingTrivia)
                )))
            )
        }
        
        return super.visit(newNode)
    }
    
//    override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
//        var newNode = node
//        
//        if let enumSymbol: SwiftSourceClassSymbol = parentStack.last as? SwiftSourceClassSymbol {
//            var newElements: [EnumCaseElementSyntax] = [EnumCaseElementSyntax]()
//            node.elements.forEach { enumCaseElemSyntax in
//                let enumCaseSymbol: SwiftSourceEnumCaseSymbol? = SwiftConfusedHelper.findChildSymbol(enumSymbol, enumCaseElemSyntax.name.text, .enumCase) as? SwiftSourceEnumCaseSymbol
//
//                if let enumCaseSymbol {
//                    let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(enumCaseSymbol)
//                    var element = enumCaseElemSyntax
//                        .with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
//                            .with(\.leadingTrivia, enumCaseElemSyntax.name.leadingTrivia)
//                            .with(\.trailingTrivia, enumCaseElemSyntax.name.trailingTrivia))
//                        .with(\.leadingTrivia, enumCaseElemSyntax.leadingTrivia)
//                        .with(\.trailingTrivia, enumCaseElemSyntax.trailingTrivia)
//                    
//                    if let parameterClause: EnumCaseParameterClauseSyntax = enumCaseElemSyntax.parameterClause {
//                        var confusedParameters: [EnumCaseParameterSyntax] = [EnumCaseParameterSyntax]()
//                        parameterClause.parameters.forEach { paramElemSyntax in
//                            if let typeIdent: IdentifierTypeSyntax = paramElemSyntax.type.as(IdentifierTypeSyntax.self),
//                               let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(typeIdent.name.text) {
//                                let confusedTypeSymbolName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol)
//                                let confusedParam = EnumCaseParameterSyntax(stringLiteral: confusedTypeSymbolName)
//                                    .with(\.leadingTrivia, paramElemSyntax.leadingTrivia)
//                                    .with(\.trailingTrivia, paramElemSyntax.trailingTrivia)
//                                confusedParameters.append(confusedParam)
//                            }
//                        }
//                        
//                        element = element.with(\.parameterClause, parameterClause.with(\.parameters, EnumCaseParameterListSyntax(confusedParameters)))
//                    }
//                    
//                    newElements.append(element)
//                }
//            }
//            
//            newNode = node.with(\.elements, EnumCaseElementListSyntax(newElements)
//                .with(\.leadingTrivia, node.elements.leadingTrivia)
//                .with(\.trailingTrivia, node.elements.trailingTrivia))
//        }
//        
//        return super.visit(newNode)
//    }
    
    override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        var newNode = node
        
        if let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(node.name.text) {
            let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol)
            newNode = newNode.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
                .with(\.leadingTrivia, newNode.leadingTrivia)
                .with(\.trailingTrivia, newNode.trailingTrivia)
            )
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: DictionaryTypeSyntax) -> TypeSyntax {
        var newNode = node
        
        if let keySyntax: IdentifierTypeSyntax = node.key.as(IdentifierTypeSyntax.self),
           let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(keySyntax.name.text) {
            let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol)
            newNode = newNode.with(\.key, TypeSyntax(keySyntax
                .with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
                    .with(\.leadingTrivia, keySyntax.name.leadingTrivia)
                    .with(\.trailingTrivia, keySyntax.name.trailingTrivia)
                ))
            )
        }
        
        if let valueSyntax: IdentifierTypeSyntax = node.value.as(IdentifierTypeSyntax.self),
           let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(valueSyntax.name.text) {
            let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol)
            newNode = newNode.with(\.value, TypeSyntax(valueSyntax
                .with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
                    .with(\.leadingTrivia, valueSyntax.name.leadingTrivia)
                    .with(\.trailingTrivia, valueSyntax.name.trailingTrivia)
                ))
            )
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ArrayTypeSyntax) -> TypeSyntax {
        var newNode = node
        
        if let elemSyntax: IdentifierTypeSyntax = node.element.as(IdentifierTypeSyntax.self),
           let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(elemSyntax.name.text) {
            let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol)
            newNode = newNode.with(\.element, TypeSyntax(elemSyntax
                .with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
                    .with(\.leadingTrivia, elemSyntax.name.leadingTrivia)
                    .with(\.trailingTrivia, elemSyntax.name.trailingTrivia)
                )
            ))
        }
        
        return super.visit(newNode)
    }

//    override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
//        self.switchExprStack.append(node)
//        return super.visit(node)
//    }
//
//    override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
//        SwiftSourceScopeManager.sharedManager.pushScope()
//        return super.visit(node)
//    }
//
//    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
//        var newNode = node
//
//        if let base = node.base {
//           if let baseTypeName = SwiftConfusedHelper.inferExprSyntaxType(base),
//              let typeSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(baseTypeName) as? SwiftSourceClassSymbol {
//
//               if let symbol: SwiftSourceSymbol = SwiftConfusedHelper.findChildSymbol(typeSymbol, node.declName.baseName.text) {
//                   let confusedSymbol = SwiftConfusedHelper.confusedSymbol(symbol)
//                   newNode = newNode.with(\.declName, newNode.declName
//                    .with(\.baseName,TokenSyntax(stringLiteral: confusedSymbol)
//                        .with(\.leadingTrivia, newNode.declName.baseName.leadingTrivia)
//                        .with(\.trailingTrivia, newNode.declName.baseName.trailingTrivia))
//                   )
//               }
//           }
//        }
//
//        return super.visit(newNode)
//    }
//
//    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
//        var newNode = node
//        
//        var clsSymbol: SwiftSourceClassSymbol?
//        var calledFunctionName: String?
//        if let memberAccessExpr: MemberAccessExprSyntax = node.calledExpression.as(MemberAccessExprSyntax.self) {
//            if let baseExpr = memberAccessExpr.base,
//               let typeSymbolName: String = SwiftConfusedHelper.inferExprSyntaxType(baseExpr) {
//                clsSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(typeSymbolName) as? SwiftSourceClassSymbol
//                calledFunctionName = memberAccessExpr.declName.baseName.text
//            }
//        } else if let calledExpression: DeclReferenceExprSyntax = node.calledExpression.as(DeclReferenceExprSyntax.self),
//                  let clsDecl: ClassDeclSyntax = SwiftConfusedHelper.findNodeParent(node, .classDecl)?.as(ClassDeclSyntax.self) {
//            clsSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(clsDecl.name.text) as? SwiftSourceClassSymbol
//            calledFunctionName = calledExpression.baseName.text
//        }
//        
//        if let clsSymbol,
//           let calledFunctionName {
//            if let funcSymbol: SwiftSourceFunctionSymbol = SwiftConfusedHelper.findChildSymbol(clsSymbol, calledFunctionName, .function) as? SwiftSourceFunctionSymbol {
//                let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(funcSymbol)
//                if let memberAccessExpr: MemberAccessExprSyntax = node.calledExpression.as(MemberAccessExprSyntax.self) {
//                    newNode = newNode.with(\.calledExpression, ExprSyntax(memberAccessExpr
//                        .with(\.declName, memberAccessExpr.declName
//                            .with(\.baseName, TokenSyntax(stringLiteral: confusedSymbolName)
//                                .with(\.leadingTrivia, memberAccessExpr.declName.baseName.leadingTrivia)
//                                .with(\.trailingTrivia, memberAccessExpr.declName.baseName.trailingTrivia)
//                            )
//                        )
//                    ))
//                } else if let calledExpression: DeclReferenceExprSyntax = node.calledExpression.as(DeclReferenceExprSyntax.self) {
//                    newNode = newNode.with(\.calledExpression, ExprSyntax(calledExpression
//                        .with(\.baseName, TokenSyntax(stringLiteral: confusedSymbolName)
//                            .with(\.leadingTrivia, calledExpression.baseName.leadingTrivia)
//                            .with(\.trailingTrivia, calledExpression.baseName.trailingTrivia)
//                        )
//                    ))
//                }
//                
//                var labeledExprListSyntax: [LabeledExprSyntax] = [LabeledExprSyntax]()
//                node.arguments.forEach { labeledExprSyntax in
//                    var confusedLabelExprSyntax = labeledExprSyntax
//                    
//                    var matchedLabelSymbol: SwiftSourceSymbol?
//                    if let label = labeledExprSyntax.label {
//                        for labelSymbol: SwiftSourceSymbol in funcSymbol.labels {
//                            if label.text != labelSymbol.originalSymbol {
//                                continue
//                            }
//                            
//                            matchedLabelSymbol = labelSymbol
//                            break
//                        }
//                        
//                        if let matchedLabelSymbol {
//                            let _ = SwiftConfusedHelper.confusedSymbol(funcSymbol)
//                            if let confusedLabelName: String = matchedLabelSymbol.confusedSymbol {
//                                confusedLabelExprSyntax = labeledExprSyntax
//                                    .with(\.label, TokenSyntax(stringLiteral: confusedLabelName)
//                                        .with(\.leadingTrivia, label.leadingTrivia)
//                                        .with(\.trailingTrivia, label.trailingTrivia)
//                                    )
//                            }
//                            
//                            if let memberAccessExpr: MemberAccessExprSyntax = labeledExprSyntax.expression.as(MemberAccessExprSyntax.self) {
//                                if memberAccessExpr.base == nil,
//                                   let labelType: String = matchedLabelSymbol.symbolType,
//                                   let typeSymbol: SwiftSourceClassSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(labelType) as? SwiftSourceClassSymbol,
//                                   let childSymbol: SwiftSourceSymbol = SwiftConfusedHelper.findChildSymbol(typeSymbol, memberAccessExpr.declName.baseName.text) {
//                                    
//                                    let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(childSymbol)
//                                    confusedLabelExprSyntax = confusedLabelExprSyntax
//                                        .with(\.expression, ExprSyntax(memberAccessExpr
//                                            .with(\.declName, memberAccessExpr.declName
//                                                .with(\.baseName, TokenSyntax(stringLiteral: confusedSymbolName)
//                                                    .with(\.leadingTrivia, memberAccessExpr.declName.baseName.leadingTrivia)
//                                                    .with(\.trailingTrivia, memberAccessExpr.declName.baseName.trailingTrivia)
//                                                )
//                                            )
//                                        ))
//                                }
//                            }
//                        }
//                    }
//                    
//                    labeledExprListSyntax.append(confusedLabelExprSyntax)
//                }
//                
//                newNode = newNode
//                    .with(\.arguments, LabeledExprListSyntax(labeledExprListSyntax)
//                        .with(\.leadingTrivia, node.arguments.leadingTrivia).with(\.trailingTrivia, node.arguments.trailingTrivia)
//                    )
//            }
//        }
//        
//        return super.visit(newNode)
//    }
//
    override func visit(_ node: OptionalTypeSyntax) -> TypeSyntax {
        var newNode = node
        
        if let wrappedType: IdentifierTypeSyntax = node.wrappedType.as(IdentifierTypeSyntax.self),
           let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(wrappedType.name.text) {
            let confusedSymbolName: String = SwiftConfusedHelper.confusedSymbol(typeSymbol)
            newNode = newNode.with(\.wrappedType, TypeSyntax(
                wrappedType.with(\.name, TokenSyntax(stringLiteral: confusedSymbolName)
                    .with(\.leadingTrivia, wrappedType.name.leadingTrivia)
                    .with(\.trailingTrivia, wrappedType.name.trailingTrivia)
                )
            ))
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
        var newNode = node
        
        var confusedParameters: [TupleTypeElementSyntax] = [TupleTypeElementSyntax]()
        node.parameters.forEach { tupleTypeElemSyntax in
            var confusedTupleTypeElemSyntax = tupleTypeElemSyntax
            if let secondName: TokenSyntax = tupleTypeElemSyntax.secondName {
                confusedTupleTypeElemSyntax = tupleTypeElemSyntax
                    .with(\.secondName, TokenSyntax(stringLiteral: SwiftConfusedHelper.confusedSymbolName(secondName.text))
                        .with(\.leadingTrivia, secondName.leadingTrivia)
                        .with(\.trailingTrivia, secondName.trailingTrivia)
                    )
            }
            
            confusedParameters.append(confusedTupleTypeElemSyntax)
        }
        
        newNode = node.with(\.parameters, TupleTypeElementListSyntax(confusedParameters)
            .with(\.leadingTrivia, node.parameters.leadingTrivia)
            .with(\.trailingTrivia, node.parameters.trailingTrivia)
        )
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: TupleTypeSyntax) -> TypeSyntax {
        var newNode = node
        
        var confusedElements: [TupleTypeElementSyntax] = [TupleTypeElementSyntax]()
        node.elements.forEach { tupleTypeElemSyntax in
            if let funcTypeSyntax: FunctionTypeSyntax = tupleTypeElemSyntax.type.as(FunctionTypeSyntax.self) {
                let newTypeNode = self.visit(funcTypeSyntax)
                confusedElements.append(tupleTypeElemSyntax
                    .with(\.type, newTypeNode
                        .with(\.leadingTrivia, funcTypeSyntax.leadingTrivia)
                        .with(\.trailingTrivia, funcTypeSyntax.trailingTrivia)
                    ))
            } else {
                confusedElements.append(tupleTypeElemSyntax)
            }
        }
        
        newNode = newNode.with(\.elements, TupleTypeElementListSyntax(confusedElements)
            .with(\.leadingTrivia, newNode.elements.leadingTrivia)
            .with(\.trailingTrivia, newNode.elements.trailingTrivia))
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClosureShorthandParameterSyntax) -> ClosureShorthandParameterSyntax {
        var newNode = node
        
        if let varSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(node.name.text) {
            let confusedName: String = SwiftConfusedHelper.confusedSymbol(varSymbol)
            newNode = newNode.with(\.name, TokenSyntax(stringLiteral: confusedName).with(\.leadingTrivia, node.name.leadingTrivia).with(\.trailingTrivia, node.name.trailingTrivia)
            )
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClosureParameterSyntax) -> ClosureParameterSyntax {
        var newNode = node
        
        var symbolName: String = node.firstName.text
        if let secondName = newNode.secondName {
            symbolName = secondName.text
        }
        
        if let varSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(symbolName) {
            let confusedName = SwiftConfusedHelper.confusedSymbol(varSymbol)
            if let secondName: TokenSyntax = node.secondName {
                newNode = newNode.with(\.secondName, TokenSyntax(stringLiteral: confusedName)
                    .with(\.leadingTrivia, secondName.leadingTrivia)
                    .with(\.trailingTrivia, secondName.trailingTrivia)
                )
            } else {
                newNode = newNode.with(\.firstName, TokenSyntax(stringLiteral: confusedName)
                    .with(\.leadingTrivia, node.firstName.leadingTrivia)
                    .with(\.trailingTrivia, node.firstName.trailingTrivia)
                )
            }
            
            if let idType: IdentifierTypeSyntax = node.type?.as(IdentifierTypeSyntax.self),
               let typeSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(idType.name.text) {
                let confusedTypeSymbol: String = SwiftConfusedHelper.confusedSymbol(typeSymbol)
                newNode = newNode.with(\.type, TypeSyntax(idType
                    .with(\.name, TokenSyntax(stringLiteral: confusedTypeSymbol)
                         )
                ))
            }
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        var newNode = node
        
        SwiftSourceScopeManager.sharedManager.pushScope(false)
        
        if let captureList: ClosureCaptureClauseSyntax = node.signature?.capture {
            var confusedCaptureList: [ClosureCaptureSyntax] = [ClosureCaptureSyntax]()
            captureList.items.forEach { closureCaptureSyntax in
                var confusedClosureCaptureSyntax = closureCaptureSyntax
                if let tokenSymbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(closureCaptureSyntax.name.text),
                   let confusedSymbol = tokenSymbol.confusedSymbol {
                    confusedClosureCaptureSyntax = confusedClosureCaptureSyntax
                        .with(\.name, TokenSyntax(stringLiteral: confusedSymbol)
                            .with(\.leadingTrivia, closureCaptureSyntax.name.leadingTrivia)
                            .with(\.trailingTrivia, closureCaptureSyntax.name.trailingTrivia)
                        )
                }
                
                confusedCaptureList.append(confusedClosureCaptureSyntax)
            }
            
            newNode = newNode.with(\.signature, newNode.signature?
                .with(\.capture, newNode.signature?.capture?
                    .with(\.items, ClosureCaptureListSyntax(confusedCaptureList))
                )
            )
        }
        
        return super.visit(newNode)
    }
    
    override func visitPost(_ node: Syntax) {
        switch node.kind {
            
        case .classDecl, .structDecl, .protocolDecl, .enumDecl, .extensionDecl, .functionDecl,
                .variableDecl, .forStmt, .repeatStmt, .doStmt, .whileStmt, .ifExpr,
                .closureExpr, .initializerDecl, .caseItem:
            SwiftSourceScopeManager.sharedManager.popScope()
        
//        case .switchExpr:
//            if !self.switchExprStack.isEmpty {
//                self.switchExprStack.removeLast()
//            }
            
        default:
            break
        }
    }
}
