//
//  SPSwiftSourceASTBuilder.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/7/8.
//

import SwiftSyntax
import SwiftSyntaxBuilder

class SPSwiftSourceASTBuilder {
//    import Foundation
//    extension [UInt8] {
//        var decryptedString: String {
//            let key: UInt8 = 0x5A
//            let decoded = self.map { $0 ^ key }
//            
//            return String(bytes: decoded, encoding: .utf8) ?? ""
//        }
//    }
    
    func buildDecryptedFunctionWithKey(_ key: String) -> SourceFileSyntax {
        let importDeclSyntax: ImportDeclSyntax = ImportDeclSyntax(
            leadingTrivia: .newlines(2),
            path: [
                ImportPathComponentSyntax(name: .identifier("Foundation"))
            ],
            trailingTrivia: .newlines(2)
        )
        
        let keyVarDecl: VariableDeclSyntax = VariableDeclSyntax(bindingSpecifier: .keyword(.let), bindings: [
            PatternBindingSyntax(
                pattern: IdentifierPatternSyntax(identifier: .identifier(ConfuseHelper.confusedSymbolName("key", confusedMap: nil))),
                typeAnnotation: TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: .identifier("UInt8"))),
                initializer: InitializerClauseSyntax(value: IntegerLiteralExprSyntax(literal: .identifier(key)))
            )
        ])
        
        let decodedVarDecl: VariableDeclSyntax = VariableDeclSyntax(bindingSpecifier: .keyword(.let), bindings: [
            PatternBindingSyntax(
                pattern: IdentifierPatternSyntax(identifier: .identifier(ConfuseHelper.confusedSymbolName("decodedString", confusedMap: nil))),
                typeAnnotation: TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: .identifier("[UInt8]"))),
                initializer: InitializerClauseSyntax(
                    value: FunctionCallExprSyntax(
                        calledExpression: MemberAccessExprSyntax(
                            base: IdentifierExprSyntax(baseName: .identifier("self")),
                            name: .identifier("map")
                        ),
                        arguments: [],
                        trailingClosure: ClosureExprSyntax(statementsBuilder: {
                            InfixOperatorExprSyntax(
                                leftOperand: IdentifierExprSyntax(
                                    baseName: .dollarIdentifier("$0")
                                ),
                                operator: BinaryOperatorExprSyntax(operator: .identifier("^")),
                                rightOperand: IdentifierExprSyntax(
                                    baseName: .identifier(ConfuseHelper.confusedSymbolName("key", confusedMap: nil))
                                )
                            )
                        })
                    )
                )
            )
        ])
        
        let retStmt: ReturnStmtSyntax = ReturnStmtSyntax(
            leadingTrivia: .newlines(2),
            expression: InfixOperatorExprSyntax(
                leftOperand: FunctionCallExprSyntax(
                    calledExpression: DeclReferenceExprSyntax(
                        baseName: .identifier("String")
                    ),
                    leftParen: .leftParenToken(),
                    rightParen: .rightParenToken(),
                    argumentsBuilder: {
                        LabeledExprSyntax(
                            label: "bytes",
                            expression: DeclReferenceExprSyntax(
                                baseName: .identifier(ConfuseHelper.confusedSymbolName("decodedString", confusedMap: nil))
                            )
                        )
                        LabeledExprSyntax(
                            label: "encoding",
                            expression: MemberAccessExprSyntax(
                                name: .identifier("utf8")
                            )
                        )
                    }
                ),
                operator: BinaryOperatorExprSyntax(operator: .identifier("??")),
                rightOperand: IdentifierExprSyntax(baseName: .identifier("\"\""))
            )
        )
        
        let accessorBlock: AccessorBlockSyntax = AccessorBlockSyntax(
            accessors: AccessorBlockSyntax.Accessors(CodeBlockItemListSyntax(itemsBuilder: {
                keyVarDecl
                decodedVarDecl
                retStmt
            }))
        )
        
        let decryptedVariableDecl: VariableDeclSyntax = VariableDeclSyntax(bindingSpecifier: .keyword(.var), bindings: [
            PatternBindingSyntax(
                pattern: IdentifierPatternSyntax(identifier: .identifier(ConfuseHelper.confusedSymbolName("decryptedString", confusedMap: nil))),
                typeAnnotation: TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: .identifier("String"))),
                accessorBlock: accessorBlock
            ),
        ])
        
        let extensionDeclSyntax: ExtensionDeclSyntax = ExtensionDeclSyntax(
            extendedType: IdentifierTypeSyntax(name: .identifier("[UInt8]"))
        ) {
            decryptedVariableDecl
        }
        
        let sourceCode: SourceFileSyntax = SourceFileSyntax {
            importDeclSyntax
            extensionDeclSyntax
        }
        
        return sourceCode
    }
}

extension String {
    func decrypt() -> String {
        return self
    }
}
