//
//  SwiftConfusedHelper.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/17.
//

import SwiftSyntax

class SwiftConfusedHelper {
    static func isMemberVariable(_ node: DeclSyntaxProtocol) -> Bool {
        var currentNode: Syntax? = node.as(Syntax.self)
        
        while let parent = currentNode?.parent {
            switch parent.kind {
            case .classDecl, .structDecl, .enumDecl, .extensionDecl:
                return true
            default:
                currentNode = parent
                break
            }
        }
        
        return false
    }
    
    static func confusedSymbolName(_ symbol: String, minLength: Int = 1, maxLength: Int = 31) -> String {
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
        
        return randomSymbolName
    }
}

extension SwiftConfusedHelper {
    static func promoteBuiltInType(left: String, right: String) -> String {
        if left == right {
            return left
        }
        
        let table = [
            "Int8", "Int16", "Int", "Int32", "Int64", "Int128",
            "UInt8", "UInt16", "UInt", "UInt32", "UInt64", "UInt128",
            "Float", "Float32", "Double", "Float64", "Float80"
        ]
        
        if let leftIndex: Int = table.firstIndex(of: left),
           let rightIndex: Int = table.firstIndex(of: right) {
            return leftIndex > rightIndex ? left : right
        }
        
        return left
    }
    
    static func inferMemberAccessExprSyntaxType(_ memberAccessExpr: MemberAccessExprSyntax) -> String? {
        var symbol: SwiftSourceSymbol?
        var isStaticType: Bool = false
        
        if let baseExpr: DeclReferenceExprSyntax = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self) {
            if baseExpr.baseName.text == "Self" {
                isStaticType = true
            }
            
            symbol = SwiftSourceScopeManager.sharedManager.findSymbol(.class)
        }
        
        if let declName: DeclReferenceExprSyntax = memberAccessExpr.declName.as(DeclReferenceExprSyntax.self),
           let children = symbol?.children {
            for (name, child) in children {
                if name == declName.baseName.text && (child.isStatic == isStaticType || child.isClass == isStaticType) {
                    return child.symbolType
                }
            }
        }
        
        return nil
    }
    
    private static func lookupSymbolNodeForExpr(_ expr: ExprSyntaxProtocol?, baseSymbol: SwiftSourceSymbol? = nil) -> SwiftSourceSymbol? {
        
        if let baseExpr: DeclReferenceExprSyntax = expr?.as(DeclReferenceExprSyntax.self) {
            if baseExpr.baseName.text == "self" {
                return SwiftSourceScopeManager.sharedManager.findSymbol(.class)
            } else if baseExpr.baseName.text == "Self" {
                return SwiftSourceScopeManager.sharedManager.findSymbol(.class)
            } else {
                if let baseSymbol: SwiftSourceClassSymbol = baseSymbol as? SwiftSourceClassSymbol {
                    for (name, child) in baseSymbol.children {
                        if String(name.prefix(baseExpr.baseName.text.count)) == baseExpr.baseName.text {
                            return child
                        }
                    }
                } else {
                    let symbol = SwiftSourceScopeManager.sharedManager.findSymbol(baseExpr.baseName.text)
                    if symbol?.nodeKind == .class {
                        
                    }
                    
                    return symbol
                }
                
                return nil
            }
        } else if let baseExpr: FunctionCallExprSyntax = expr?.as(FunctionCallExprSyntax.self) {
            if let baseSymbol: SwiftSourceClassSymbol = baseSymbol as? SwiftSourceClassSymbol {
                if let calledExpr: DeclReferenceExprSyntax = baseExpr.calledExpression.as(DeclReferenceExprSyntax.self) {
                    for (name, child) in baseSymbol.children {
                        if String(name.prefix(calledExpr.baseName.text.count)) == calledExpr.baseName.text {
                            return child
                        }
                    }
                }
            } else if let calledExpr: MemberAccessExprSyntax = baseExpr.calledExpression.as(MemberAccessExprSyntax.self) {
                let symbol = self.lookupSymbolNodeForExpr(calledExpr, baseSymbol: baseSymbol)
                if symbol?.nodeKind == .function,
                   let symbol: SwiftSourceFunctionSymbol = symbol as? SwiftSourceFunctionSymbol {
                    return SwiftSourceScopeManager.sharedManager.findSymbol(symbol.returnType)
                }
            }
        } else if let baseExpr: MemberAccessExprSyntax = expr?.as(MemberAccessExprSyntax.self) {
            let baseSymbol = self.lookupSymbolNodeForExpr(baseExpr.base, baseSymbol: baseSymbol) as? SwiftSourceClassSymbol
            return self.lookupSymbolNodeForExpr(baseExpr.declName, baseSymbol: baseSymbol)
        }
        
        return nil
    }
    
    static func inferFunctionCallExprSyntaxType(_ functionCallExpr: FunctionCallExprSyntax, isIntance: Bool = false) -> String? {
        if let callExpr: DeclReferenceExprSyntax = functionCallExpr.calledExpression.as(DeclReferenceExprSyntax.self) {
            if callExpr.baseName.text.isSwiftKeyWord {
                /// 类型转换
                return callExpr.baseName.text
            } else if let symbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(callExpr.baseName.text, isIntance: isIntance) {
                return symbol.symbolType
            }
        } else if let callExpr: MemberAccessExprSyntax = functionCallExpr.calledExpression.as(MemberAccessExprSyntax.self) {
            let symbol = self.lookupSymbolNodeForExpr(callExpr.base)
            if let declName: DeclReferenceExprSyntax = callExpr.declName.as(DeclReferenceExprSyntax.self) {
                if symbol?.nodeKind == .class,
                   let children = symbol?.children {
                    for (name, child) in children {
                        if child.nodeKind != .function {
                            continue
                        }
                        
                        if String(name.prefix(declName.baseName.text.count)) == declName.baseName.text {
                            return (child as? SwiftSourceFunctionSymbol)?.returnType
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    static func inferClosureExprSyntaxType(_ closureExpr: ClosureExprSyntax) -> String? {
        var typeString: String?
        
        if let parameters: ClosureParameterListSyntax = closureExpr.signature?.parameterClause?.as(ClosureParameterClauseSyntax.self)?.parameters.as(ClosureParameterListSyntax.self) {
            if parameters.count == 0 {
                typeString = "()"
            } else {
                typeString = "(\(parameters.trimmedDescription))"
            }
        }
        
        if let returnClause: ReturnClauseSyntax = closureExpr.signature?.returnClause {
            if let identTypeSyntax: IdentifierTypeSyntax = returnClause.type.as(IdentifierTypeSyntax.self) {
                typeString = ((typeString != nil) ? typeString! : "()") + " -> \(identTypeSyntax.name.text)"
            }
        } else {
            if let expr: ExprSyntax = closureExpr.statements.last?.item.as(ExprSyntax.self),
               let stmtType: String = self.inferExprSyntaxType(expr) {
                typeString = ((typeString != nil) ? typeString! : "()") + " -> \(stmtType)"
            }
        }
        
        return typeString
    }
    
    static func inferExprSyntaxType(_ expr: ExprSyntaxProtocol, isIntance: Bool = true) -> String? {
        if let _ = expr.as(IntegerLiteralExprSyntax.self) {
            return "Int"
        } else if let _ = expr.as(StringLiteralExprSyntax.self) {
            return "String"
        } else if let _ = expr.as(FloatLiteralExprSyntax.self) {
            return "Double"
        } else if let _ = expr.as(ArrayExprSyntax.self) {
            return "Array"
        } else if let _ = expr.as(DictionaryExprSyntax.self) {
            return "Dictionary"
        } else if let closureExpr: ClosureExprSyntax = expr.as(ClosureExprSyntax.self) {
            return self.inferClosureExprSyntaxType(closureExpr)
        } else if let _ = expr.as(BooleanLiteralExprSyntax.self) {
            return "Bool"
        } else if let _ = expr.as(RegexLiteralExprSyntax.self) {
            return "Regex"
        } else if let callExprSyntax: FunctionCallExprSyntax = expr.as(FunctionCallExprSyntax.self) {
            return self.inferFunctionCallExprSyntaxType(callExprSyntax)
        } else if let declRefExpr: DeclReferenceExprSyntax = expr.as(DeclReferenceExprSyntax.self) {
            if declRefExpr.baseName.text == "self" || declRefExpr.baseName.text == "Self",
               let symbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(.class) {
                return symbol.originalSymbol
            } else if let symbol: SwiftSourceSymbol = SwiftSourceScopeManager.sharedManager.findSymbol(declRefExpr.baseName.text, isIntance: isIntance) {
                return symbol.symbolType
            }
        } else if let macroExpr: MacroExpansionExprSyntax = expr.as(MacroExpansionExprSyntax.self) {
            let macroName = macroExpr.macroName.text
            switch macroName {
            case "file", "fileID", "filePath", "function":
                return "String"
            case "line", "column":
                return "Int"
            default:
                break
            }
        } else if let memberAccessExpr: MemberAccessExprSyntax = expr.as(MemberAccessExprSyntax.self) {
            return self.inferMemberAccessExprSyntaxType(memberAccessExpr)
        } else if let forceUnwrapExpr: ForceUnwrapExprSyntax = expr.as(ForceUnwrapExprSyntax.self) {
            return self.inferExprSyntaxType(forceUnwrapExpr.expression)
        } else if let _ = expr.as(TupleExprSyntax.self) {
            
        } else if let _ = expr.as(SubscriptCallExprSyntax.self) {
            
        } else if let _ = expr.as(KeyPathExprSyntax.self) {
            
        } else if let infixOperatorExpr = expr.as(InfixOperatorExprSyntax.self) {
            if let oper: BinaryOperatorExprSyntax = infixOperatorExpr.operator.as(BinaryOperatorExprSyntax.self) {
                if oper.isBooleanOperator {
                    return "Bool"
                }
                
                let leftOperand = self.inferExprSyntaxType(infixOperatorExpr.leftOperand)
                let rightOperand = self.inferExprSyntaxType(infixOperatorExpr.rightOperand)
                
                if let leftOperand, let rightOperand {
                    return self.promoteBuiltInType(left: leftOperand, right: rightOperand)
                }
                
                return leftOperand
            }
        } else if let _ = expr.as(IsExprSyntax.self) {
            return "Bool"
        } else if let prefixOper: PrefixOperatorExprSyntax = expr.as(PrefixOperatorExprSyntax.self) {
            if prefixOper.operator.text == "!" {
                return "Bool"
            }
        }
        
        return nil  // 暂时无法推导
    }
}

extension BinaryOperatorExprSyntax {
    var isBooleanOperator: Bool {
        let oper: [String] = [
            "==", "!=", "===", "!==",
            "<", ">", "<=", ">=",
            "~="
        ]
        
        return oper.contains(self.operator.text)
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
