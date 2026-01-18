//
//  SwiftSourceSymbol.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/12.
//
import Foundation
import SwiftSyntax

enum SwiftNodeKind {
    case unknown
    case `class`
    case variable
    case `function`
    case label
    case `protocol`
    case `struct`
    case `enum`
    case enumCase
}

enum SwiftSourceAccessControl {
    case Open
    case Public
    case Internal
    case Package
    case FilePrivate
    case Private
}

class SwiftSourceSymbol {
    /// 结点类型
    var nodeKind: SwiftNodeKind = .unknown
    
    /// 惟一标识
    var identifier: String?
    
    /// 文件路径
    var symbolFilePath: String?
    
    /// 原始符号
    var originalSymbol: String? {
        didSet {
            self.identifier = originalSymbol
        }
    }
    
    /// 混淆符号
    var confusedSymbol: String?
    
    /// 符号类型
    var symbolType: String?
    
    /// AST结点
    var ASTNode: SyntaxProtocol?
    
    /// 父结点
    var parent: SwiftSourceSymbol?
    
    /// 访问控制
    var accessControl: SwiftSourceAccessControl = .Internal
    
    /// 静态
    var isStatic: Bool = false
    
    /// override
    var isOverride: Bool = false
    
    /// 类变量
    var isClass: Bool = false
    
    /// final
    var isFinal: Bool = false
    
    /// 成员
    var isMember: Bool = false
    
    init(nodeKind: SwiftNodeKind) {
        self.nodeKind = nodeKind
    }
}

/// 类类型
class SwiftSourceClassSymbol: SwiftSourceSymbol {
    /// 继承列表
    var inheritedType: [String]?
}

/// 方法类型
class SwiftSourceFunctionSymbol: SwiftSourceSymbol {
    /// 返回类型
    var returnType: String = "Void"
    
    /// 标签
    lazy var labels: [SwiftSourceSymbol] = [SwiftSourceSymbol]()
}

class SwiftSourceEnumCaseSymbol: SwiftSourceSymbol {
    lazy var relatedType: [String] = [String]()
}
