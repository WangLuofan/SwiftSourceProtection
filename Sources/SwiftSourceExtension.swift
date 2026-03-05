//
//  SwiftSourceExtension.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/2/7.
//

import SwiftSyntax

protocol SwiftClassDeclProtocol {
    var name: SwiftSyntax.TokenSyntax { get }
    var inheritanceClause: InheritanceClauseSyntax? { get }
    var modifiers: DeclModifierListSyntax { get }
    
    func symbol(_ nodeKind: SwiftNodeKind, _ sourceFile: String) -> SwiftSourceClassSymbol
}

extension SwiftClassDeclProtocol {
    func symbol(_ nodeKind: SwiftNodeKind, _ sourceFile: String) -> SwiftSourceClassSymbol {
        let classSymbol: SwiftSourceClassSymbol = SwiftSourceClassSymbol(nodeKind: nodeKind)
        
        classSymbol.symbolFilePath = sourceFile
        classSymbol.parent = parentStack.last
        classSymbol.originalSymbol = self.name.text
        classSymbol.symbolType = self.name.text
        classSymbol.ASTNode = self as? SyntaxProtocol
        
        if let inheritedTypes = self.inheritanceClause?.inheritedTypes {
            inheritedTypes.forEach { inheritedTypeSyntax in
                if let idTypeSyntax: IdentifierTypeSyntax = inheritedTypeSyntax.type.as(IdentifierTypeSyntax.self) {
                    classSymbol.inheritedType.append(idTypeSyntax.name.text)
                }
            }
        }
        
        self.modifiers.forEach { modifier in
            classSymbol.accessControl = modifier.accessControl
            classSymbol.isFinal = modifier.isFinal
        }
        
        return classSymbol
    }
}

protocol SwiftFunctionDeclProtocol {
    var name: TokenSyntax { get }
    var modifiers: DeclModifierListSyntax { get }
    var signature: FunctionSignatureSyntax { get }
    var isMemberDecl: Bool { get }
    
    func symbol(_ sourceFile: String) -> SwiftSourceFunctionSymbol
}

extension SwiftFunctionDeclProtocol {
    func symbol(_ sourceFile: String) -> SwiftSourceFunctionSymbol {
        let funcSymbol: SwiftSourceFunctionSymbol = SwiftSourceFunctionSymbol()
        funcSymbol.symbolFilePath = sourceFile
        funcSymbol.parent = parentStack.last
        funcSymbol.originalSymbol = self.name.text
        self.modifiers.forEach { modifier in
            funcSymbol.accessControl = modifier.accessControl
            funcSymbol.isStatic = modifier.isStatic
            funcSymbol.isFinal = modifier.isFinal
            funcSymbol.isClass = modifier.isClass
            funcSymbol.isOverride = modifier.isOverride
        }
        
        funcSymbol.returnType = "Void"
        if let identSyntax: IdentifierTypeSyntax = self.signature.returnClause?.type.as(IdentifierTypeSyntax.self) {
            funcSymbol.returnType = identSyntax.name.text
        }
        
        funcSymbol.ASTNode = self as? SyntaxProtocol
        funcSymbol.isMember = self.isMemberDecl
        
        // symbol|static|return|signature
        self.signature.parameterClause.parameters.forEach { parameterSyntax in
            
            let funcLabel: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .label)
            funcLabel.parent = funcSymbol
            funcLabel.originalSymbol = parameterSyntax.firstName.text
            funcLabel.symbolFilePath = sourceFile
            
            funcSymbol.labels[parameterSyntax.firstName.text] = funcLabel
        }
        
        funcSymbol.signature = SwiftConfusedHelper.generateFunctionSignature(self)
        
        return funcSymbol
    }
}

extension String {
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

extension DeclSyntaxProtocol {
    var isMemberDecl: Bool {
        var currentNode: Syntax? = self.as(Syntax.self)

        while let parent = currentNode?.parent {
            switch parent.kind {
            case .classDecl, .structDecl, .enumDecl, .extensionDecl, .protocolDecl:
                return true
            case .functionDecl, .variableDecl:
                return false
            default:
                currentNode = parent
                break
            }
        }

        return false
    }

    var isGlobalDecl: Bool {
        var currentNode: Syntax? = self.as(Syntax.self)

        while let parent = currentNode?.parent {
            switch parent.kind {
            case .sourceFile:
                return true
            case .classDecl, .structDecl, .enumDecl,
                    .extensionDecl, .protocolDecl, .functionDecl,
                    .closureExpr, .initializerDecl, .deinitializerDecl,
                    .subscriptDecl, .accessorDecl, .variableDecl:
                return false
            default:
                currentNode = parent
                break
            }
        }

        return false
    }

    var isLocalDecl: Bool {
        var currentNode: Syntax? = self.as(Syntax.self)

        while let parent = currentNode?.parent {
            switch parent.kind {
            case .functionDecl, .closureExpr, .initializerDecl,
                    .deinitializerDecl, .subscriptDecl, .accessorDecl:
                return true
            case .sourceFile:
                return false
            default:
                currentNode = parent
                break
            }
        }

        return false
    }
}

extension ClassDeclSyntax: SwiftClassDeclProtocol {
    
}

extension StructDeclSyntax: SwiftClassDeclProtocol {
    
}

extension EnumDeclSyntax: SwiftClassDeclProtocol {
    
}

extension ExtensionDeclSyntax: SwiftClassDeclProtocol {
    var name: SwiftSyntax.TokenSyntax {
        if let idName: IdentifierTypeSyntax = self.extendedType.as(IdentifierTypeSyntax.self) {
            return idName.name
        }
        
        return TokenSyntax(stringLiteral: "")
    }
    
}

extension ProtocolDeclSyntax: SwiftClassDeclProtocol {
    
}

extension FunctionDeclSyntax: SwiftFunctionDeclProtocol {
    
}

extension InitializerDeclSyntax: SwiftFunctionDeclProtocol {
    var name: SwiftSyntax.TokenSyntax {
        return "init"
    }
}

extension VariableDeclSyntax {
    func variableSymbol(_ sourceFile: String) -> SwiftSourceSymbol {
        let variableSymbol: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
        variableSymbol.symbolFilePath = sourceFile
        variableSymbol.parent = parentStack.last
        self.modifiers.forEach { modifier in
            variableSymbol.accessControl = modifier.accessControl
            variableSymbol.isStatic = modifier.isStatic
            variableSymbol.isFinal = modifier.isFinal
            variableSymbol.isClass = modifier.isClass
            variableSymbol.isOverride = modifier.isOverride
        }
        
        variableSymbol.ASTNode = self
        self.bindings.forEach { [weak variableSymbol] patternBinding in
            guard let variableSymbol else {
                return
            }
            
            if let identPatternBinding: IdentifierPatternSyntax = patternBinding.pattern.as(IdentifierPatternSyntax.self) {
                variableSymbol.originalSymbol = identPatternBinding.identifier.text
            }
            
            if let typeAnnotation: TypeAnnotationSyntax = patternBinding.typeAnnotation {
                if let typeId: IdentifierTypeSyntax = typeAnnotation.type.as(IdentifierTypeSyntax.self) {
                    variableSymbol.symbolType = typeId.name.text
                } else if let optType: OptionalTypeSyntax = typeAnnotation.type.as(OptionalTypeSyntax.self),
                          let wrappedType: IdentifierTypeSyntax = optType.wrappedType.as(IdentifierTypeSyntax.self) {
                    variableSymbol.symbolType = wrappedType.name.text
                }
            } else if let initializer: InitializerClauseSyntax = patternBinding.initializer {
                variableSymbol.symbolType = SwiftConfusedHelper.inferExprSyntaxType(initializer.value)
            }
        }
        
        variableSymbol.isMember = self.isMemberDecl
        return variableSymbol
    }
}

extension FunctionParameterSyntax {
    func funcParameterSymbol(_ sourceFile: String) -> SwiftSourceSymbol {
        let paramSymbol: SwiftSourceSymbol = SwiftSourceSymbol(nodeKind: .variable)
        if let secondName {
            paramSymbol.originalSymbol = secondName.text
        } else {
            paramSymbol.originalSymbol = firstName.text
        }
        
        if let typeIdent: IdentifierTypeSyntax = self.type.as(IdentifierTypeSyntax.self) {
            paramSymbol.symbolType = typeIdent.name.text
        }
        
        paramSymbol.ASTNode = self
        paramSymbol.parent = parentStack.last
        
        return paramSymbol
    }
}
