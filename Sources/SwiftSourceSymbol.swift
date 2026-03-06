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
    
    /// 文件路径
    var symbolFilePath: String?
    
    /// 原始符号
    var originalSymbol: String = ""
    
    /// 混淆符号
    var confusedSymbol: String?
    
    /// 符号类型
    var symbolType: String?
    
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
    
    /// AST结点
    var ASTNode: SyntaxProtocol?
    
    /// 是否类声明结点
    var isClassNodeKind: Bool {
        switch self.nodeKind {
        case .class, .protocol, .struct, .enum:
            return true
        default:
            break
        }
        
        return false
    }
    
    /// 子声明
    lazy var children: [SwiftSourceSymbol] = [SwiftSourceSymbol]()
    
    init(nodeKind: SwiftNodeKind) {
        self.nodeKind = nodeKind
    }
}

/// 类类型
class SwiftSourceClassSymbol: SwiftSourceSymbol {
    /// 继承列表
    lazy var inheritedType: [String] = [String]()
    
    func mergeSymbol(_ clsSymbol: SwiftSourceClassSymbol) {
        clsSymbol.children.forEach { symbol in
            symbol.parent = self
            
            self.children.append(symbol)
        }
        
        if !clsSymbol.inheritedType.isEmpty {
            self.inheritedType.append(contentsOf: clsSymbol.inheritedType)
        }
    }
}

/// 方法类型
class SwiftSourceFunctionSymbol: SwiftSourceSymbol {
    /// 返回类型
    var returnType: String = "Void"
    
    /// 签名
    var signature: String = ""
    
    /// 标签
    lazy var labels: [String: SwiftSourceSymbol] = [String: SwiftSourceSymbol]()
    
    init() {
        super.init(nodeKind: .function)
    }
}

class SwiftSourceEnumCaseSymbol: SwiftSourceSymbol {
    lazy var associatedType: [String] = [String]()
}
