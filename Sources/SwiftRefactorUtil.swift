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
        let startTrivia = TriviaPiece.lineComment("// class_start-")
        let endTrivia = TriviaPiece.lineComment("// class_end-")
        
        var leadingTrivia = node.leadingTrivia + Trivia(pieces: [startTrivia, .newlines(1)])
        var skipFirstNewLine: Bool = true
        
        node.leadingTrivia.pieces.forEach { piece in
            if piece.isNewline && skipFirstNewLine {
                skipFirstNewLine = false
                return
            }
            leadingTrivia = leadingTrivia.appending(piece)
        }
        
        let traillingTrivia = node.trailingTrivia + Trivia(pieces: [.newlines(1), endTrivia, .newlines(1)])
        
        let newNode = node.with(\.leadingTrivia, leadingTrivia).with(\.trailingTrivia, traillingTrivia)
        return super.visit(newNode)
    }
    
    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        let parent: Syntax? = node.parent
        
        if parent?.as(MemberBlockItemSyntax.self) == nil {
            return super.visit(node)
        }
        
        let startTrivia = TriviaPiece.lineComment("// attribute_start-")
        let endTrivia = TriviaPiece.lineComment("// attribute_end-")
        
        var leadingTrivia = Trivia(pieces: [.newlines(1), startTrivia])
        node.leadingTrivia.pieces.forEach { piece in
            leadingTrivia = leadingTrivia.appending(piece)
        }
        
        let trailingTrivia = node.trailingTrivia + Trivia(pieces: [.newlines(1), endTrivia, .newlines(1)])
        
        let newNode = node.with(\.leadingTrivia, leadingTrivia).with(\.trailingTrivia, trailingTrivia)
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let startTrivia = TriviaPiece.lineComment("// func_start-")
        let endTrivia = TriviaPiece.lineComment("// func_end-")
        
        var leadingTrivia = Trivia(pieces: [.newlines(1), startTrivia])
        node.leadingTrivia.pieces.forEach { piece in
            leadingTrivia = leadingTrivia.appending(piece)
        }
        
        let trailingTrivia = node.trailingTrivia + Trivia(pieces: [.newlines(1), endTrivia, .newlines(1)])
        
        let newNode = node.with(\.leadingTrivia, leadingTrivia).with(\.trailingTrivia, trailingTrivia)
        return super.visit(newNode)
    }
}

