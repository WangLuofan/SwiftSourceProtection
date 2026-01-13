//
//  SwiftSourceSymbol.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/12.
//
import Foundation
import SwiftSyntax

enum SwiftNodeType {
    case unknown
    case `class`
    case variable
    case `function`
    case `protocol`
    case `struct`
    case `enum`
}

class SwiftSourceSymbol {
    /// 结点类型
    var nodeType: SwiftNodeType = .unknown
    
    /// 惟一标识
    var identifier: String?
    
    /// 文件路径
    var symbolFilePath: String?
    
    /// 原始符号
    var originalSymbol: String?
    
    /// 混淆符号
    var confusedSymbol: String?
    
    /// 符号类型
    var symbolType: String?
    
    /// AST结点
    var ASTNode: SyntaxProtocol?
    
    /// 父结点
    var parent: SwiftSourceSymbol?
}
