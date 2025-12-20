//
//  SwiftASTSyntaxRewriter.swift
//  SwiftRefactorUtil
//
//  Created by WangLuofan on 2025/12/12.
//
import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

class SwiftASTSyntaxRewriter: SyntaxRewriter {
    
    private let swiftKeywords: Set<String> = [
        "self", "super", "in", "let", "var", "func", "if", "else", "for", "while",
        "return", "break", "continue", "nil", "true", "false", "guard", "switch"
    ]
    
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
            
            let isMemberType: Bool = SwiftRefactorHelper.isMemberVariable(node)
            let name = isMemberType ? "pro_\(identifierPattern.identifier.text)_pro" : "par_\(identifierPattern.identifier.text)_par"
            
            let newPattern = PatternSyntax(stringLiteral: name)
            return bindings.with(\.leadingTrivia, identifierPattern.leadingTrivia).with(\.pattern, newPattern).with(\.trailingTrivia, identifierPattern.trailingTrivia)
        }
        
        var newNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.bindings, PatternBindingListSyntax(updatedBindings)).with(\.trailingTrivia, node.trailingTrivia)
        
        if SwiftRefactorHelper.isMemberVariable(node) {
            newNode = self.addCommentForDeclSyntax(newNode, startTriviaString: "// attribute_start-", endTriviaString: "// attribute_end-")
        }
        
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var newNode = self.addCommentForDeclSyntax(node, startTriviaString: "// func_start-", endTriviaString: "// func_end-")
        newNode.name = TokenSyntax(stringLiteral: "fun_\(node.name.text)_fun")
        return super.visit(newNode)
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        var funcName: String = ""
        var expr: ExprSyntax?
        
        if let exp = node.calledExpression.as(DeclReferenceExprSyntax.self) {
            funcName = "func_\(exp.baseName.text)_func"
            let newToken = TokenSyntax.identifier(funcName).with(\.leadingTrivia, exp.leadingTrivia).with(\.trailingTrivia, exp.trailingTrivia)
            expr = ExprSyntax(exp.with(\.baseName, newToken))
        }  else if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self) {
            funcName = "func_\(memberAccess.declName.baseName.text)_func"
            let newDeclName = memberAccess.declName.with(\.baseName, TokenSyntax.identifier(funcName))
            expr = ExprSyntax(memberAccess.with(\.leadingTrivia, memberAccess.leadingTrivia).with(\.declName, newDeclName)).with(\.trailingTrivia, memberAccess.trailingTrivia)
        }
        
        if let expr {
            let newNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.calledExpression, expr).with(\.trailingTrivia, node.trailingTrivia)
            return super.visit(newNode)
        }
        
        return super.visit(node)
    }
    
    override func visit(_ node: ClosureCaptureSyntax) -> ClosureCaptureSyntax {
        let originName = node.name.text
        if originName.compare("self") == .orderedSame {
            return super.visit(node)
        }
        
        let newName = "par_\(originName)_par"
        
        let newNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.name, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, node.trailingTrivia)
        return super.visit(newNode)
    }
    
    override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
        var modifiedNode = node
        
        // 检查 parameterClause 的类型
        switch modifiedNode.parameterClause {
        case .simpleInput(let paramList):
            // 简写参数列表，如: text, name in
            let newParams = paramList.map { param -> ClosureShorthandParameterSyntax in
                let originName = param.name.text
                let newName = "par_\(originName)_par"
                return param.with(\.leadingTrivia, param.leadingTrivia).with(\.name, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, param.trailingTrivia)
            }
            
            modifiedNode = modifiedNode.with(\.leadingTrivia, modifiedNode.leadingTrivia).with(\.parameterClause, .simpleInput(ClosureShorthandParameterListSyntax(newParams))).with(\.trailingTrivia, modifiedNode.trailingTrivia)
            
        case .parameterClause(let paramClause):
            // 完整参数列表，如: (text: String, name: String) in
            let newParams = paramClause.parameters.map { param -> ClosureParameterSyntax in
                var modifiedParam = param
                
                // 处理内部参数名 (secondName)
                if let secondName = param.secondName {
                    let originName = secondName.text
                    let newName = "par_\(originName)_par"
                    modifiedParam = modifiedParam.with(\.leadingTrivia, modifiedParam.leadingTrivia).with(\.secondName, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, modifiedNode.trailingTrivia)
                }
                // 如果没有 secondName，使用 firstName（但跳过下划线）
                else if param.firstName.text != "_" {
                    let originName = param.firstName.text
                    let newName = "par_\(originName)_par"
                    modifiedParam = modifiedParam.with(\.leadingTrivia, modifiedParam.leadingTrivia).with(\.firstName, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, modifiedParam.trailingTrivia)
                }
                
                return modifiedParam
            }
            
            let newParamClause = paramClause.with(\.parameters, ClosureParameterListSyntax(newParams))
            modifiedNode = modifiedNode.with(\.leadingTrivia, modifiedNode.leadingTrivia).with(\.parameterClause, .parameterClause(newParamClause)).with(\.trailingTrivia, modifiedNode.trailingTrivia)
            
        default:
            break
        }
        
        return super.visit(modifiedNode)
    }
    
    // 重命名函数类型中的参数
    override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
        // 修改参数
        let newParameters = node.parameters.map { param -> TupleTypeElementSyntax in
            var modifiedParam = param
            
            // 处理内部参数名 (secondName)
            if let secondName = param.secondName {
                let originName = secondName.text
                let newName = "par_\(originName)_par"
                modifiedParam = modifiedParam.with(\.leadingTrivia, modifiedParam.leadingTrivia).with(\.secondName, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, modifiedParam.trailingTrivia)
            }
            // 处理外部参数名 (firstName)，跳过下划线
            else if let firstName = param.firstName,
                    firstName.text != "_" {
                let originName = firstName.text
                let newName = "par_\(originName)_par"
                modifiedParam = modifiedParam.with(\.leadingTrivia, modifiedParam.leadingTrivia).with(\.firstName, TokenSyntax(stringLiteral: newName)).with(\.trailingTrivia, modifiedParam.trailingTrivia)
            }
            
            return modifiedParam
        }
        
        // 创建修改后的节点
        let modifiedNode = node.with(\.leadingTrivia, node.leadingTrivia).with(\.parameters, TupleTypeElementListSyntax(newParameters)).with(\.trailingTrivia, node.trailingTrivia)
        
        // 重要：调用 super.visit 来继续处理子节点
        return super.visit(modifiedNode)
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
