//
//  SPSwiftSourceASTRewriter.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import Foundation
import SwiftSyntax

class SPSwiftSourceASTRewriter: SyntaxRewriter {
    private var sourceTree: SourceFileSyntax
    private var sourceFile: File
    private var relatedDict: [UInt64: SPSwiftSourceSymbol]
    
    init(sourceTree: SourceFileSyntax, sourceFile: File, relatedDict: [UInt64 : SPSwiftSourceSymbol]) {
        self.sourceTree = sourceTree
        self.sourceFile = sourceFile
        self.relatedDict = relatedDict
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: TokenSyntax) -> TokenSyntax {
        let indexInTree: UInt64 = node.id.indexInTree.toOpaque()
        
        guard let symbol: SPSwiftSourceSymbol = self.relatedDict[indexInTree],
              let confusedSymbolName = symbol.confusedSymbolName else {
            return super.visit(node)
        }
        
        return super.visit(node.with(\.tokenKind, .identifier(confusedSymbolName)))
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let signature = ConfuseHelper.generateSignature(funcName: node.name.text, parameters: node.signature.parameterClause.parameters)
        
        guard let scope = IndexStore.indexStore.scope(nodeID: node.id.indexInTree.toOpaque(), inFile: self.sourceFile),
           let funcSymbol: SPSwiftSourceFunctionSymbol = scope.findSymbolWithSymbolName(signature) as? SPSwiftSourceFunctionSymbol else {
            return super.visit(node)
        }
        
        var confusedParams: [FunctionParameterSyntax] = []
        node.signature.parameterClause.parameters.forEach {
            for (index, label) in funcSymbol.labels.enumerated() {
                if label == $0.firstName.text {
                    confusedParams.append($0
                        .with(\.firstName, .identifier(
                            funcSymbol.confusedLabels[index],
                            leadingTrivia: $0.firstName.leadingTrivia,
                            trailingTrivia: $0.firstName.trailingTrivia)
                        )
                    )
                    break
                } else {
                    confusedParams.append($0)
                }
            }
        }
        
        let newNode = node.with(\.signature, node.signature
            .with(\.parameterClause, node.signature.parameterClause
                .with(\.parameters, FunctionParameterListSyntax(confusedParams))
                .with(\.leadingTrivia, node.signature.parameterClause.parameters.leadingTrivia)
                .with(\.trailingTrivia, node.signature.parameterClause.parameters.trailingTrivia))
                .with(\.leadingTrivia, node.signature.parameterClause.leadingTrivia)
                .with(\.trailingTrivia, node.signature.parameterClause.trailingTrivia)
        )
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        var confusedElements: [EnumCaseElementSyntax] = []
        node.elements.forEach {
            guard let params = $0.parameterClause?.parameters else {
                confusedElements.append($0)
                return
            }
            
            var confusedParams: [EnumCaseParameterSyntax] = []
            params.forEach {
                guard let firstName = $0.firstName else {
                    confusedParams.append($0)
                    return
                }
                
                let confusedFistName: String = ConfuseHelper.confusedSymbolName(firstName.text)
                confusedParams.append($0.with(\.firstName, .identifier(confusedFistName, leadingTrivia: firstName.leadingTrivia, trailingTrivia: firstName.trailingTrivia)))
            }
            
            confusedElements.append($0.with(\.parameterClause, $0.parameterClause?
                .with(\.parameters, EnumCaseParameterListSyntax(confusedParams)
                    .with(\.leadingTrivia, params.leadingTrivia)
                    .with(\.trailingTrivia, params.trailingTrivia)))
            )
        }
        
        newNode = newNode.with(\.elements, EnumCaseElementListSyntax(confusedElements)
            .with(\.leadingTrivia, node.elements.leadingTrivia)
            .with(\.trailingTrivia, node.elements.trailingTrivia)
        )
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard let symbol = self.getRelateCallExpressionId(node.calledExpression) else {
            return super.visit(node)
        }
        
        var newNode = node
        var finalFuncSymbol: SPSwiftSourceFunctionSymbol?
        
        if let clsSymbol: SPSwiftSourceClassSymbol = symbol as? SPSwiftSourceClassSymbol {
            let labels: [String] = node.arguments.map { $0.label?.text ?? "_" }
            
            for funcSymbol in clsSymbol.children {
                guard let funcSymbol: SPSwiftSourceFunctionSymbol = funcSymbol as? SPSwiftSourceFunctionSymbol,
                      funcSymbol.originalSymbolName == "init" else {
                    continue
                }
                
                var validInitializer: Bool = true
                for label in labels {
                    if funcSymbol.labels.contains(label) == false {
                        validInitializer = false
                        break
                    }
                }
                
                if !validInitializer {
                    continue
                }
                
                finalFuncSymbol = funcSymbol
                break
            }
        } else if let funcSymbol: SPSwiftSourceFunctionSymbol = symbol as? SPSwiftSourceFunctionSymbol {
            finalFuncSymbol = funcSymbol
        }
        
        if let finalFuncSymbol {
            var confusedArgs: [LabeledExprSyntax] = []
            node.arguments.forEach {
                if let label = $0.label {
                    for (index, text) in finalFuncSymbol.labels.enumerated() {
                        if text == label.text {
                            confusedArgs.append($0.with(\.label, .identifier(finalFuncSymbol.confusedLabels[index], leadingTrivia: label.leadingTrivia, trailingTrivia: label.trailingTrivia)))
                            break
                        }
                    }
                } else {
                    confusedArgs.append($0)
                }
            }
            
            newNode = newNode.with(\.arguments, LabeledExprListSyntax(confusedArgs)
                .with(\.leadingTrivia, node.arguments.leadingTrivia)
                .with(\.trailingTrivia, node.arguments.trailingTrivia)
            )
            
            var confusedMultipleTrailingClosureElemSyntax: [MultipleTrailingClosureElementSyntax] = []
            newNode.additionalTrailingClosures.forEach {
                for (index, label) in finalFuncSymbol.labels.enumerated() {
                    if label == $0.label.text {
                        confusedMultipleTrailingClosureElemSyntax.append($0
                            .with(\.label, .identifier(
                                finalFuncSymbol.confusedLabels[index],
                                leadingTrivia: $0.label.leadingTrivia,
                                trailingTrivia: $0.label.trailingTrivia)
                            )
                        )
                        return
                    }
                }
                
                confusedMultipleTrailingClosureElemSyntax.append($0)
            }
            
            newNode = newNode.with(\.additionalTrailingClosures, MultipleTrailingClosureElementListSyntax(confusedMultipleTrailingClosureElemSyntax)
                .with(\.leadingTrivia, newNode.additionalTrailingClosures.leadingTrivia)
                .with(\.trailingTrivia, newNode.additionalTrailingClosures.trailingTrivia)
            )
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
        if node.macroName.text == "selector" {
            
            var confusedArgs: [LabeledExprSyntax] = []
            node.arguments.forEach {
                if let declRefExpr: DeclReferenceExprSyntax = $0.expression.as(DeclReferenceExprSyntax.self),
                    let funcSymbol: SPSwiftSourceFunctionSymbol = self.getRelateCallExpressionId($0.expression) as? SPSwiftSourceFunctionSymbol,
                   let argumentNames = declRefExpr.argumentNames {
                    
                    var confusedArgNames: [DeclNameArgumentSyntax] = []
                    for (index, arg) in argumentNames.arguments.enumerated() {
                        confusedArgNames.append(arg
                            .with(\.name, .identifier(
                                funcSymbol.confusedLabels[index],
                                leadingTrivia: arg.name.leadingTrivia,
                                trailingTrivia: arg.name.trailingTrivia)
                            )
                        )
                    }
                    
                    confusedArgs.append($0
                        .with(\.expression, ExprSyntax(
                            declRefExpr.with(\.argumentNames, argumentNames
                                .with(\.arguments, DeclNameArgumentListSyntax(confusedArgNames)
                                     )
                            )
                        ))
                    )
                } else {
                    confusedArgs.append($0)
                }
            }
            
            let newNode = node.with(\.arguments, LabeledExprListSyntax(confusedArgs)
                .with(\.leadingTrivia, node.arguments.leadingTrivia)
                .with(\.trailingTrivia, node.arguments.trailingTrivia)
            )
            return super.visit(newNode)
        }
        
        return super.visit(node)
    }
}

extension SPSwiftSourceASTRewriter {
    func rewrite() -> SourceFileSyntax {
        let rewritedSyntax: SourceFileSyntax = self.visit(self.sourceTree)
        return rewritedSyntax
    }
    
    private func getRelateCallExpressionId(_ calledExpression: ExprSyntaxProtocol) -> SPSwiftSourceSymbol? {
        if let declRefExprSyntax: DeclReferenceExprSyntax = calledExpression.as(DeclReferenceExprSyntax.self) {
            let indexInTree: UInt64 = declRefExprSyntax.baseName.id.indexInTree.toOpaque()
            return self.relatedDict[indexInTree]
        } else if let memAccExprSyntax: MemberAccessExprSyntax = calledExpression.as(MemberAccessExprSyntax.self) {
            return self.getRelateCallExpressionId(memAccExprSyntax.declName)
        }
        
        return nil
    }
}
