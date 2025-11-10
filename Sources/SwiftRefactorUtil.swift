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
        var newNode = self.addCommentForDeclSyntax(node, startTrivia: "// class_start-", endTrivia: "// class_end-")
        newNode.name = TokenSyntax(stringLiteral: "cla_\(node.name.text)_cla")
        return super.visit(newNode)
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        let newNode = self.addCommentForDeclSyntax(node, startTrivia: "// class_start-", endTrivia: "// class_end-")
        return super.visit(newNode)
    }
    
    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        var newNode = self.addCommentForDeclSyntax(node, startTrivia: "// class_start-", endTrivia: "// class_end-")
        newNode.name = TokenSyntax(stringLiteral: "cla_\(node.name.text)_cla")
        return super.visit(newNode)
    }
    
    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        var newNode = self.addCommentForDeclSyntax(node, startTrivia: "// class_start-", endTrivia: "// class_end-")
        newNode.name = TokenSyntax(stringLiteral: "cla_\(node.name.text)_cla")
        return super.visit(newNode)
    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        let parent: Syntax? = node.parent
        
        if parent?.as(MemberBlockItemSyntax.self) == nil {
            return super.visit(node)
        }
        
        let newNode = self.addCommentForDeclSyntax(node, startTrivia: "// attribute_start-", endTrivia: "// attribute_end-")
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var newNode = self.addCommentForDeclSyntax(node, startTrivia: "// func_start-", endTrivia: "// func_end-")
        newNode.name = TokenSyntax(stringLiteral: "fun_\(node.name.text)_fun")
        return super.visit(newNode)
    }
}

extension SwiftASTSyntaxRewriter {
    private func addCommentForDeclSyntax<T: DeclSyntaxProtocol>(_ node: T, startTrivia: String, endTrivia: String) -> T {
        
        let startTrivia = TriviaPiece.lineComment(startTrivia)
        let endTrivia = TriviaPiece.lineComment(endTrivia)
        
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
