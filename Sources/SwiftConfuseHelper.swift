//
//  SwiftConfuseHelper.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2025/12/20.
//
import Foundation
import SwiftSyntax

class SwiftConfuseHelper {
    
    static func shouldSymbolConfused(_ symbolName: String, _ info: SwiftSourceBaseInfo? = nil) -> Bool {
        
        guard !symbolName.isSwiftKeyWord else {
            return false
        }
        
        guard let sourceInfo = info ?? self.findSymbolInScope(symbolName) else {
            return false
        }
        
        switch sourceInfo.sourceType {
        case .Unknown:
            return false
        case .Protocol, .Enum, .Class:
            return true
        case .Function, .Variable: do {
            if sourceInfo.isStatic || sourceInfo.isFinal || sourceInfo.accessControl == .FilePrivate
                || sourceInfo.accessControl == .Private || !sourceInfo.isMember {
                return true
            } else if sourceInfo.isOverride {
                /// 向上查找，找到最终定义位置
                /// 判断是否在用户目录
                if sourceInfo.parent == nil {
                    return false
                }
                
                guard sourceInfo.parent?.sourceType == .Class,
                        let clsSourceInfo: SwiftSourceClassInfo = sourceInfo.parent as? SwiftSourceClassInfo else {
                    return true
                }
                
                for superCls in clsSourceInfo.superClasses {
                    guard let superClsInfo: SwiftSourceClassInfo = self.findSymbolInScope(superCls) as? SwiftSourceClassInfo,
                          superClsInfo.sourceType == .Class else {
                        continue
                    }
                    
                    if self.shouldSymbolConfused(symbolName, superClsInfo) {
                        return true
                    }
                }
            } else {
                /// 如果是实现了协议，则向上查获协议，找到最终定义位置
                /// 判断是否在用户目录
                guard sourceInfo.parent != nil,
                      let clsSourceInfo: SwiftSourceClassInfo = sourceInfo.parent as? SwiftSourceClassInfo,
                      !clsSourceInfo.superClasses.isEmpty else {
                    return true
                }
                
                for superCls in clsSourceInfo.superClasses {
                    guard let superClsInfo: SwiftSourceClassInfo = self.findSymbolInScope(superCls) as? SwiftSourceClassInfo,
                          superClsInfo.sourceType == .Protocol else {
                        continue
                    }
                    
                    if self.shouldSymbolConfused(symbolName, superClsInfo) {
                        return true
                    }
                }
            }
            
            break
        }
        @unknown default:
            break
        }
        
        return false
    }
    
    private static func findSymbolInScope(_ symbolName: String, _ scope: SwiftSourceScope? = SwiftSourceScopeManager.shared.currentScope) -> SwiftSourceBaseInfo? {
        guard let scope else {
            return nil
        }
        
        for (symbol, info) in scope.symbols {
            if symbol == symbolName {
                return info
            }
        }
        
        return self.findSymbolInScope(symbolName, scope.prevScope)
    }
    
    static func confusedSymbolName(symbolName: String, bAlwaysConfuse: Bool = false, minLength: Int = 1, maxLength: Int = 31) -> String {
        
        if minLength <= 0 || maxLength >= 32 || (!bAlwaysConfuse && !Self.shouldSymbolConfused(symbolName)) {
            return symbolName
        }
        
        if let confusedSymbol = SwiftConfusedSymbolTable.shared.confusedSymbol[symbolName] {
            return confusedSymbol
        }
        
        let lowercase: String = "abcdefghijklmnopqrstuvwxyz"
        let uppercase: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let digital: String = "0123456789"
        let underScore: String = "_"
        
        let randomSymbolLength: Int = Int.random(in: minLength...maxLength)
        let firstCharset: [String.Element] = Array(lowercase + uppercase + underScore)
        
        var randomSymbolName = String(firstCharset[Int.random(in: 0..<firstCharset.count)])
        let allCharacters: [String] = [lowercase, uppercase, digital]
        
        for _ in 1..<randomSymbolLength {
            let randomIndex = Int.random(in: 0..<allCharacters.count)
            if randomIndex == 3 {
                randomSymbolName += underScore
                continue
            }
            
            let randomItem = Int.random(in: 0..<allCharacters[randomIndex].count)
            
            let stringArr: [String.Element] = Array(allCharacters[randomIndex])
            randomSymbolName += String(stringArr[randomItem])
        }
        
        if SwiftConfusedSymbolTable.shared.reversedSymbol[randomSymbolName] != nil {
            return self.confusedSymbolName(symbolName: symbolName)
        }
        
        SwiftConfusedSymbolTable.pushConfusedSymbol(symbolName, randomSymbolName)
        return randomSymbolName
    }
    
    static func isEqualSourceInfo(_ lhs: SwiftSourceBaseInfo, _ rhs: SwiftSourceBaseInfo) -> Bool {
        if lhs.sourceType != rhs.sourceType {
            return false
        }
        
        if lhs.identifier != rhs.identifier || lhs.symbolName != rhs.symbolName {
            return false
        }
        
        if let lhsFuncInfo: SwiftSourceFunctionInfo = lhs as? SwiftSourceFunctionInfo,
           let rhsFuncInfo: SwiftSourceFunctionInfo = rhs as? SwiftSourceFunctionInfo {
            return lhsFuncInfo.signature == rhsFuncInfo.signature
        }
        
        return true
    }
    
    static func isMemberVariable(_ node: DeclSyntaxProtocol) -> Bool {
        var currentNode: Syntax? = node.as(Syntax.self)
        
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
}

extension DeclModifierSyntax {
    var accessControl: SwiftSourceAccessControl {
        if self.name.text == "open" {
            return .Open
        } else if self.name.text == "public" {
            return .Public
        } else if self.name.text == "fileprivate" {
            return .FilePrivate
        } else if self.name.text == "private" {
            return .Private
        } else if self.name.text == "package" {
            return .Package
        }
        
        return .Internal
    }
    
    var isStatic: Bool {
        return self.name.text == "static"
    }
    
    var isOverride: Bool {
        return self.name.text == "override"
    }
    
    var isClass: Bool {
        return self.name.text == "class"
    }
    
    var isFinal: Bool {
        return self.name.text == "final"
    }
}

extension String {
    var isSwiftKeyWord: Bool {
        let swiftKeywords = [
            "_",
            
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
