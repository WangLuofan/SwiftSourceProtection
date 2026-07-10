//
//  Extensions.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import SwiftSyntax

extension String {
    
    var encryptedString: [UInt8] {
        let key: UInt8 = 0x5A
        let bytes: [UInt8] = Array(self.utf8)
        
        return bytes.map { $0 ^ key }
    }
    
    var isSwiftKeyWord: Bool {
        let swiftKeywords = [
            "_", "$",
            
            // 声明关键字
            "associatedtype", "class", "deinit", "enum", "extension",
            "fileprivate", "func", "import", "init", "inout",
            "internal", "let", "open", "operator", "private",
            "protocol", "public", "rethrows", "static", "struct",
            "subscript", "typealias", "var", "actor",
            
            // 语句关键字
            "break", "case", "continue", "default", "defer",
            "do", "else", "fallthrough", "for", "guard",
            "if", "in", "repeat", "return", "switch",
            "where", "while", "catch", "throw", "throws",
            
            // 表达式和类型关键字
            "Any", "as", "catch", "false", "is",
            "nil", "rethrows", "self", "Self", "super",
            "throw", "throws", "true", "try", "await",
            
            // 模式匹配
            "case", "default", "where",
            
            // 泛型和协议
            "associatedtype", "where", "some", "any",
            
            // 访问控制修饰符
            "private", "fileprivate", "internal", "public", "open",
            
            // 成员修饰符
            "convenience", "dynamic", "final", "infix", "lazy",
            "mutating", "nonmutating", "optional", "override", "postfix",
            "precedence", "prefix", "required", "static", "unowned",
            "weak", "indirect",
            
            // 函数修饰符
            "async", "consuming", "mutating", "nonmutating", "rethrows",
            "throws", "borrowing",
            
            // 参数修饰符
            "inout",
            
            // 类型修饰符
            "some", "any",
            
            // 上下文关键字（在特定上下文中是关键字）
            "_", "associativity", "convenience", "dynamic", "didSet",
            "final", "get", "infix", "indirect", "lazy",
            "left", "mutating", "none", "nonmutating", "optional",
            "override", "postfix", "precedence", "prefix", "Protocol",
            "required", "right", "set", "Type", "unowned",
            "weak", "willSet", "wrappedValue", "projectedValue",
            
            // 并发关键字
            "async", "await", "nonisolated", "isolated", "Sendable",
            "consuming", "borrowing", "consume", "borrow",
            
            // 宏系统（Swift 5.9+）
            "macro", "freestanding", "attached",
            
            // 参数包（Swift 5.9+）
            "pack", "repeat", "each",
            
            // 其他
            "available", "discardableResult", "dynamicCallable",
            "dynamicMemberLookup", "frozen", "inlinable", "main",
            "nonobjc", "NSApplicationMain", "objc", "propertyWrapper",
            "resultBuilder", "testable", "UIApplicationMain", "unchecked",
            "usableFromInline",
            
            // 特殊值
            "nil", "true", "false",
            
            // 自我引用
            "self", "Self", "super",
            
            // 循环和迭代
            "for", "while", "repeat", "in",
            
            // 控制转移
            "break", "continue", "fallthrough", "return",
            
            // 错误处理
            "throw", "throws", "rethrows", "catch", "try",
            
            // 条件判断
            "if", "else", "guard", "switch", "case", "default",
            
            // 延迟执行
            "defer",
            
            // 类型检查和转换
            "is", "as", "as?", "as!", "Any", "AnyObject",
            
            // 模式匹配
            "where",
            
            // 异步/并发
            "async", "await",
            
            // 基础类型
            "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
            "Float", "Double", "Float16", "Float32", "Float64", "Float80",
            "Bool",
            "String", "Character", "Substring",
            
            // 集合类型
            "Array", "Dictionary", "Set",
            "Range", "ClosedRange", "PartialRangeFrom",
            "PartialRangeThrough", "PartialRangeUpTo",
            "ArraySlice",
            
            // 可选和错误
            "Optional",
            "Error", "ErrorProtocol", "Result",
            
            // 指针类型
            "UnsafePointer", "UnsafeMutablePointer",
            "UnsafeBufferPointer", "UnsafeMutableBufferPointer",
            "UnsafeRawPointer", "UnsafeMutableRawPointer",
            "AutoreleasingUnsafeMutablePointer",
            "Unmanaged",
            
            // 类型擦除
            "Any", "AnyObject", "AnyHashable", "AnyClass", "AnyProtocol",
            
            // 特殊类型
            "Never", "Void",
            
            // 并发（Swift 5.5+）
            "Task", "CheckedContinuation", "UnsafeContinuation",
            
            // 标准库重要类型
            "Date", "Data", "URL", "UUID",
            "Decimal", "NSNumber", "NSDecimalNumber",
            
            // 平台特定
            "CGFloat", "CGRect", "CGPoint", "CGSize",
            
            // Objective-C 桥接
            "NSString", "NSArray", "NSDictionary", "NSSet",
            "NSNumber", "NSData", "NSDate",
        ]
        
        return swiftKeywords.contains(self)
    }
}

extension SKUID {
    func declType() -> SourceKit.DeclarationType? {
        if let t = declarationType() { return t }
        let s = asString
        
        if s.contains("function.constructor") {
            return .method
        }
        
        return nil
    }
    
    func refType() -> SourceKit.DeclarationType? {
        if let t = referenceType() { return t }
        let s = asString
        
        if s.contains("function.constructor") {
            return .method
        }
        
        return nil
    }
}

extension SyntaxProtocol {
    func getParentNode<T: SyntaxProtocol>() -> T? {
        var current = self.parent
        while current != nil {
            if let node: T = current?.as(T.self) {
                return node
            }
            
            current = current?.parent
        }
        
        return nil
    }
    
    var symbolScope: SymbolScope {
        var current = self.parent

        while let syntax = current {
            switch syntax.kind {
            case .functionDecl, .initializerDecl, .closureExpr, .accessorBlock:
                return .local
            case .structDecl, .classDecl, .enumDecl, .actorDecl, .extensionDecl, .protocolDecl:
                return .member
            default:
                break
            }
            
            current = syntax.parent
        }

        return .global
    }
}

extension [UInt8] {
    var decryptedString: String {
        let key: UInt8 = 0x5A
        let decoded = self.map { $0 ^ key }
        
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }
}
