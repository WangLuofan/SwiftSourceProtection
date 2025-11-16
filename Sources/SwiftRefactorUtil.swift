//
//  SwiftRefactorUtil.swift
//  SwiftRefactorUtil
//
//  Created by 王落凡 on 2025/10/28.
//

import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

public class SwiftRefactorUtil {
    private let sourceCode: String
    
    init(_ sourceCode: String) {
        self.sourceCode = sourceCode
    }
    
    public func rewrite() -> String {
        let rewriter = SwiftASTSyntaxRewriter()
        let sourceFile = Parser.parse(source: self.sourceCode)
        
        let rewritten = rewriter.visit(sourceFile)
        print(rewritten.description)
        
        return rewritten.description
    }
}

private class SwiftASTSyntaxRewriter: SyntaxRewriter {
    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        var newNode = self.addCommentForDeclSyntax(node, startTriviaString: "// class_start-", endTriviaString: "// class_end-")
        newNode.name = TokenSyntax(stringLiteral: "cla_\(node.name.text)_cla")
        return super.visit(newNode)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        var newNode = self.addCommentForDeclSyntax(node, startTriviaString: "// class_start-", endTriviaString: "// class_end-")
        
        if let extendedType = node.extendedType.as(IdentifierTypeSyntax.self) {
            let newExtendedType = IdentifierTypeSyntax(
                name: TokenSyntax.identifier("cla_\(extendedType.name.text)_cla"),
                genericArgumentClause: extendedType.genericArgumentClause
            )
            
            newNode = newNode.with(\.extendedType, TypeSyntax(newExtendedType))
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        var newNode = self.addCommentForDeclSyntax(node, startTriviaString: "// class_start-", endTriviaString: "// class_end-")
        newNode.name = TokenSyntax(stringLiteral: "cla_\(node.name.text)_cla")
        return super.visit(newNode)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        var newNode = self.addCommentForDeclSyntax(node, startTriviaString: "// class_start-", endTriviaString: "// class_end-")
        newNode.name = TokenSyntax(stringLiteral: "cla_\(node.name.text)_cla")
        return super.visit(newNode)
    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        
        let updatedBindings: [PatternBindingSyntax] = node.bindings.map { bindings in
            guard let identifierPattern = bindings.pattern.as(IdentifierPatternSyntax.self) else {
                return bindings
            }
            
            let isMemberType: Bool = self.isMemberVariable(node)
            let name = isMemberType ? "pro_\(identifierPattern.identifier.text)_pro" : "par_\(identifierPattern.identifier.text)_par"
            
            let newPattern = PatternSyntax(stringLiteral: name)
                .with(\.trailingTrivia, node.trailingTrivia)
            return bindings.with(\.pattern, newPattern)
        }
        
        var newNode = node.with(\.bindings, PatternBindingListSyntax(updatedBindings))
        
        if self.isMemberVariable(node) {
            newNode = self.addCommentForDeclSyntax(newNode, startTriviaString: "// attribute_start-", endTriviaString: "// attribute_end-")
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var newNode = self.addCommentForDeclSyntax(node, startTriviaString: "// func_start-", endTriviaString: "// func_end-")
        newNode.name = TokenSyntax(stringLiteral: "fun_\(node.name.text)_fun")
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionParameterSyntax) -> FunctionParameterSyntax {
        var newNode = node
        
        let newFirstNameText = node.firstName.text.compare("_") == .orderedSame ? node.firstName.text : "par_\(node.firstName.text)_par"
        
        let newFirstNameToken = TokenSyntax.identifier(newFirstNameText).with(\.leadingTrivia, node.firstName.leadingTrivia).with(\.trailingTrivia, node.firstName.trailingTrivia)
            
        newNode = newNode.with(\.firstName, newFirstNameToken)
        
        if let originalSecondName = node.secondName {
            let newSecondNameText = "par_\(originalSecondName.text)_par"
            let newSecondNameToken = TokenSyntax.identifier(newSecondNameText)
                .with(\.leadingTrivia, originalSecondName.leadingTrivia)
                .with(\.trailingTrivia, originalSecondName.trailingTrivia)
            newNode = newNode.with(\.secondName, newSecondNameToken)
        }
        
        newNode = newNode
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
        
        return super.visit(newNode)
    }
}

extension SwiftASTSyntaxRewriter {
    private func isStaticVariable(_ node: VariableDeclSyntax) -> Bool {
        for modifier in node.modifiers {
            if modifier.name.text.compare("static") == .orderedSame {
                return true
            }
        }
        
        return false
    }
    
    private func isMemberVariable(_ node: VariableDeclSyntax) -> Bool {
        var currentNode: Syntax? = Syntax(node)
        
        while let parent = currentNode?.parent {
            switch parent.kind {
            case .classDecl, .structDecl, .enumDecl, .extensionDecl:
                return true
            case .functionDecl, .closureExpr, .codeBlock, .ifExpr, .forStmt, .whileStmt, .repeatStmt, .switchExpr:
                return false
            default:
                currentNode = parent
            }
        }
        
        return false
    }
    
    private func addCommentForDeclSyntax<T: DeclSyntaxProtocol>(_ node: T, startTriviaString: String, endTriviaString: String) -> T {
        
        let startTrivia = TriviaPiece.lineComment(startTriviaString)
        let endTrivia = TriviaPiece.lineComment(endTriviaString)
        
        var leadingTrivia = Trivia(pieces: [.newlines(1), startTrivia])
        node.leadingTrivia.pieces.forEach { piece in
            leadingTrivia = leadingTrivia.appending(piece)
        }
        
        let trailingTrivia = node.trailingTrivia + Trivia(pieces: [.newlines(1), endTrivia, .newlines(1)])
        
        let newNode = node.with(\.leadingTrivia, leadingTrivia).with(\.trailingTrivia, trailingTrivia)
        return newNode
    }
    
    private func renameForDeclSyntax<T: DeclSyntaxProtocol>(_ node: T, prefix: String) -> T {
        return node
    }
}
