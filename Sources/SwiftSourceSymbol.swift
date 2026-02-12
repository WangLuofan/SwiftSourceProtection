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
    case `extension`
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
    var identifier: String = ""
    
    /// 惟一标识名称
    var identifierName: String {
        if let identifier = self.identifier.split(separator: "|").first {
            return String(identifier)
        }
        
        return ""
    }
    
    /// 文件路径
    var symbolFilePath: String?
    
    /// 原始符号
    var originalSymbol: String = "" {
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
    
    /// 静态成员
    var isStatic: Bool = false
    
    /// override
    var isOverride: Bool = false
    
    /// 类成员
    var isClass: Bool = false
    
    /// final
    var isFinal: Bool = false
    
    /// 成员
    var isMember: Bool = false
    
    /// 子作用域
    var childScope: SwiftSourceScope?
    
    /// 子声明
    lazy var children: [SwiftSourceSymbol] = [SwiftSourceSymbol]()
    
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
    lazy var labels: [String: SwiftSourceSymbol] = [String: SwiftSourceSymbol]()
}

class SwiftSourceEnumCaseSymbol: SwiftSourceSymbol {
    lazy var associatedType: [String] = [String]()
}
