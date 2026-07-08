//
//  SPSwiftSourceASTBuilder.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/7/8.
//

import SwiftSyntax
import SwiftSyntaxBuilder

class SPSwiftSourceASTBuilder {
    func build() {
        let source = SourceFileSyntax {
            ImportDeclSyntax(
                path: [
                    ImportPathComponentSyntax(name: .identifier("Foundation"), trailingTrivia: .newlines(2)),
                ]
            )
            
            ExtensionDeclSyntax(
                extendedType: ArrayTypeSyntax(element: IdentifierTypeSyntax(name: .identifier("UInt8")))
            ) {
                FunctionDeclSyntax(
                    name: .identifier("decrypt"),
                    signature: .init(
                        parameterClause: .init(parameters: []),
                        returnClause: .init(type: IdentifierTypeSyntax(name: .identifier("String")))
                    )
                ) {
                    VariableDeclSyntax(
                        bindingSpecifier: .keyword(.let),
                    ) {
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("key")),
                            typeAnnotation: TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: .identifier("Int"))),
                            initializer: .init(value: IntegerLiteralExprSyntax(literal: .integerLiteral("0x5A")))
                        )
                    }
                    
                    VariableDeclSyntax(
                        bindingSpecifier: .keyword(.let)
                    ) {
                        PatternBindingSyntax(
                            pattern: IdentifierPatternSyntax(identifier: .identifier("decrypted")),
                            typeAnnotation: TypeAnnotationSyntax(type: ArrayTypeSyntax(element: IdentifierTypeSyntax(name: .identifier("UInt8")))),
                            initializer: .init(value: FunctionCallExprSyntax(calledExpression: MemberAccessExprSyntax(base: IdentifierExprSyntax(baseName: .identifier("self")), name: .identifier("map")), arguments: [], trailingClosure: ClosureExprSyntax(statements: [
                                CodeBlockItemSyntax(
                                    item: .expr(
                                        ExprSyntax(
                                            InfixOperatorExprSyntax(
                                                leftOperand: ExprSyntax(
                                                    IdentifierExprSyntax(
                                                        identifier: .dollarIdentifier("$0")
                                                    )
                                                ),
                                                operator: BinaryOperatorExprSyntax(operator: .identifier("^")),
                                                rightOperand: ExprSyntax(
                                                    IdentifierExprSyntax(
                                                        identifier: .identifier("key")
                                                    )
                                                )
                                            ))
                                    )
                                )
                            ])))
                        )
                    }
                }
            }
        }
        
        print(source.formatted().description)
    }
}

extension String {
    func decrypt() -> String {
        return self
    }
}
