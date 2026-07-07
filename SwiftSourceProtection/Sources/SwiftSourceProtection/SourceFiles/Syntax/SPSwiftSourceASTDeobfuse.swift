//
//  SPSwiftSourceASTDeobfuse.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2026/7/5.
//

import Foundation
import SwiftSyntax

class SPSwiftSourceASTDeobfuse: SyntaxRewriter {
    private var sourceTree: SourceFileSyntax
    private var sourceFile: File
    private var confusedMap: [String: String]
    
    init(sourceTree: SourceFileSyntax, sourceFile: File, confusedMap: [String : String]) {
        self.sourceTree = sourceTree
        self.sourceFile = sourceFile
        self.confusedMap = confusedMap
        
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: TokenSyntax) -> TokenSyntax {
        guard let originalSymbolName: String = self.confusedMap[node.text] else {
            return super.visit(node)
        }
        
        return super.visit(node.with(\.tokenKind, .identifier(originalSymbolName)))
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var originalParams: [FunctionParameterSyntax] = []
        node.signature.parameterClause.parameters.forEach {
            var originalParam = $0
            if let originFirstName: String = self.confusedMap[$0.firstName.text] {
                originalParam = originalParam.with(\.firstName, .identifier(
                    originFirstName,
                    leadingTrivia: $0.firstName.leadingTrivia,
                    trailingTrivia: $0.firstName.trailingTrivia)
                )
            }
            
            if let secondName = $0.secondName,
               let originSecondName: String = self.confusedMap[secondName.text] {
                originalParam = originalParam.with(\.secondName, .identifier(
                    originSecondName,
                    leadingTrivia: secondName.leadingTrivia,
                    trailingTrivia: secondName.trailingTrivia)
                )
            }
            
            originalParams.append(originalParam)
        }
        
        let newNode = node.with(\.signature, node.signature
            .with(\.parameterClause, node.signature.parameterClause
                .with(\.parameters, FunctionParameterListSyntax(originalParams)
                    .with(\.leadingTrivia, node.signature.parameterClause.parameters.leadingTrivia)
                    .with(\.trailingTrivia, node.signature.parameterClause.parameters.trailingTrivia)
                )
            )
            .with(\.leadingTrivia, node.signature.parameterClause.leadingTrivia)
            .with(\.trailingTrivia, node.signature.parameterClause.trailingTrivia)
        )
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
        var newNode = node
        
        var originalElements: [EnumCaseElementSyntax] = []
        node.elements.forEach {
            guard let params = $0.parameterClause?.parameters else {
                originalElements.append($0)
                return
            }
            
            var originalParams: [EnumCaseParameterSyntax] = []
            params.forEach {
                guard let firstName = $0.firstName else {
                    originalParams.append($0)
                    return
                }
                
                if let originalFistName: String = self.confusedMap[firstName.text] {
                    originalParams.append($0.with(\.firstName, .identifier(originalFistName, leadingTrivia: firstName.leadingTrivia, trailingTrivia: firstName.trailingTrivia)))
                }
            }
            
            originalElements.append($0.with(\.parameterClause, $0.parameterClause?
                .with(\.parameters, EnumCaseParameterListSyntax(originalParams)
                    .with(\.leadingTrivia, params.leadingTrivia)
                    .with(\.trailingTrivia, params.trailingTrivia)))
            )
        }
        
        newNode = newNode.with(\.elements, EnumCaseElementListSyntax(originalElements)
            .with(\.leadingTrivia, node.elements.leadingTrivia)
            .with(\.trailingTrivia, node.elements.trailingTrivia)
        )
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        var newNode = node
        
        var originalArgs: [LabeledExprSyntax] = []
        node.arguments.forEach {
            if let label = $0.label,
               let originLabel: String = self.confusedMap[label.text] {
                originalArgs.append($0.with(\.label, .identifier(originLabel, leadingTrivia: label.leadingTrivia, trailingTrivia: label.trailingTrivia)))
            } else {
                originalArgs.append($0)
            }
        }
        
        newNode = newNode.with(\.arguments, LabeledExprListSyntax(originalArgs)
            .with(\.leadingTrivia, node.arguments.leadingTrivia)
            .with(\.trailingTrivia, node.arguments.trailingTrivia)
        )
        
        var originalMultipleTrailingClosureElemSyntax: [MultipleTrailingClosureElementSyntax] = []
        newNode.additionalTrailingClosures.forEach {
            if let originalLabel: String = self.confusedMap[$0.label.text] {
                originalMultipleTrailingClosureElemSyntax.append($0
                    .with(\.label, .identifier(
                        originalLabel,
                        leadingTrivia: $0.label.leadingTrivia,
                        trailingTrivia: $0.label.trailingTrivia)
                    )
                )
            } else {
                originalMultipleTrailingClosureElemSyntax.append($0)
            }
        }
        
        newNode = newNode.with(\.additionalTrailingClosures, MultipleTrailingClosureElementListSyntax(originalMultipleTrailingClosureElemSyntax)
            .with(\.leadingTrivia, newNode.additionalTrailingClosures.leadingTrivia)
            .with(\.trailingTrivia, newNode.additionalTrailingClosures.trailingTrivia)
        )
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
        if node.macroName.text == "selector" {
            
            var originalArgs: [LabeledExprSyntax] = []
            node.arguments.forEach {
                if let declRefExpr: DeclReferenceExprSyntax = $0.expression.as(DeclReferenceExprSyntax.self),
                   let argumentNames = declRefExpr.argumentNames {
                    
                    var originalArgNames: [DeclNameArgumentSyntax] = []
                    for arg in argumentNames.arguments {
                        if let originalArgName: String = self.confusedMap[arg.name.text] {
                            originalArgNames.append(arg
                                .with(\.name, .identifier(
                                    originalArgName,
                                    leadingTrivia: arg.name.leadingTrivia,
                                    trailingTrivia: arg.name.trailingTrivia)
                                )
                            )
                        } else {
                            originalArgNames.append(arg)
                        }
                    }
                    
                    originalArgs.append($0
                        .with(\.expression, ExprSyntax(
                            declRefExpr.with(\.argumentNames, argumentNames
                                .with(\.arguments, DeclNameArgumentListSyntax(originalArgNames)
                                     )
                            )
                        ))
                    )
                } else {
                    originalArgs.append($0)
                }
            }
            
            let newNode = node.with(\.arguments, LabeledExprListSyntax(originalArgs)
                .with(\.leadingTrivia, node.arguments.leadingTrivia)
                .with(\.trailingTrivia, node.arguments.trailingTrivia)
            )
            
            return super.visit(newNode)
        }
        
        return super.visit(node)
    }
}

extension SPSwiftSourceASTDeobfuse {
    func deobfuse() -> SourceFileSyntax {
        let rewritedSyntax: SourceFileSyntax = self.visit(self.sourceTree)
        return rewritedSyntax
    }
}
