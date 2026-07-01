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
                    confusedParams.append($0.with(\.firstName, .identifier(funcSymbol.confusedLabels[index], leadingTrivia: $0.firstName.leadingTrivia, trailingTrivia: $0.firstName.trailingTrivia)))
                    break
                }
            }
        }
        
        let newNode = node.with(\.signature, node.signature.with(\.parameterClause, node.signature.parameterClause.with(\.parameters, FunctionParameterListSyntax(confusedParams))
            .with(\.leadingTrivia, node.signature.parameterClause.parameters.leadingTrivia)
            .with(\.trailingTrivia, node.signature.parameterClause.parameters.trailingTrivia)
        ))
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard let symbol = self.getRelateCallExpressionId(node.calledExpression) else {
            return super.visit(node)
        }
        
        var newNode = node
        
        if let clsSymbol: SPSwiftSourceClassSymbol = symbol as? SPSwiftSourceClassSymbol {
            let labels: [String] = node.arguments.map { $0.label?.text ?? "_" }
            
            for funcSymbol in clsSymbol.children {
                guard let funcSymbol: SPSwiftSourceFunctionSymbol = funcSymbol as? SPSwiftSourceFunctionSymbol,
                      funcSymbol.originalSymbolName == "init" else {
                    continue
                }
                
                for label in labels {
                    if funcSymbol.labels.contains(label) == false {
                        continue
                    }
                }
                
                var confusedArgs: [LabeledExprSyntax] = []
                node.arguments.forEach {
                    if let label = $0.label {
                        for (index, text) in funcSymbol.labels.enumerated() {
                            if text == label.text {
                                confusedArgs.append($0.with(\.label, .identifier(funcSymbol.confusedLabels[index], leadingTrivia: label.leadingTrivia, trailingTrivia: label.trailingTrivia)))
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
                
                break
            }
        } else if let funcSymbol: SPSwiftSourceFunctionSymbol = symbol as? SPSwiftSourceFunctionSymbol {
            var confusedArgs: [LabeledExprSyntax] = []
            node.arguments.forEach {
                if let label = $0.label {
                    
                    for (index, text) in funcSymbol.labels.enumerated() {
                        if text == label.text {
                            confusedArgs.append($0.with(\.label, .identifier(funcSymbol.confusedLabels[index], leadingTrivia: label.leadingTrivia, trailingTrivia: label.trailingTrivia)))
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
        }
        
        return super.visit(newNode)
    }
}

extension SPSwiftSourceASTRewriter {
    func rewrite() -> String {
        let rewritten = self.visit(self.sourceTree)
        return rewritten.description
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
