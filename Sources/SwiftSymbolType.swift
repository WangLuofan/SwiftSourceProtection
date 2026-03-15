//
//  SwiftSymbolType.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/3/14.
//

enum SwiftSymbolTypeKind {
    case any
    case single
    case array
    case dictionary
    case tuple
    case function
    case composition
    case someAny
}

protocol SwiftSymbolType {
    var type: SwiftSymbolTypeKind { get }
}

class SwiftSymbolAnyType: SwiftSymbolType {
    var type: SwiftSymbolTypeKind {
        return .any
    }
}

class SwiftSymbolSingleType: SwiftSymbolAnyType {
    var typeName: String
    
    override var type: SwiftSymbolTypeKind {
        return .single
    }
    
    init(typeName: String) {
        self.typeName = typeName
    }
    
    static var voidType: SwiftSymbolSingleType {
        return SwiftSymbolSingleType(typeName: "Void")
    }
    
    static func promoteBuiltInType(left: SwiftSymbolSingleType, right: SwiftSymbolSingleType) -> SwiftSymbolSingleType {
        if left.typeName == right.typeName {
            return left
        }
        
        let table = [
            "Int8", "Int16", "Int", "Int32", "Int64", "Int128",
            "UInt8", "UInt16", "UInt", "UInt32", "UInt64", "UInt128",
            "Float", "Float32", "Double", "Float64", "Float80"
        ]
        
        if let leftIndex: Int = table.firstIndex(of: left.typeName),
           let rightIndex: Int = table.firstIndex(of: right.typeName) {
            return leftIndex > rightIndex ? left : right
        }
        
        return left
    }
}

class SwiftSymbolArrayType: SwiftSymbolAnyType {
    var elementType: SwiftSymbolType
    
    override var type: SwiftSymbolTypeKind {
        return .array
    }
    
    init(elementType: SwiftSymbolType = SwiftSymbolAnyType()) {
        self.elementType = elementType
    }
}

class SwiftSymbolDictionaryType: SwiftSymbolAnyType {
    var keyType: SwiftSymbolType
    var valueType: SwiftSymbolType
    
    override var type: SwiftSymbolTypeKind {
        return .dictionary
    }
    
    init(keyType: SwiftSymbolType = SwiftSymbolAnyType(), valueType: SwiftSymbolType = SwiftSymbolAnyType()) {
        self.keyType = keyType
        self.valueType = valueType
    }
}

class SwiftSymbolTupleType: SwiftSymbolAnyType {
    override var type: SwiftSymbolTypeKind {
        return .tuple
    }
    
    lazy var elements: [SwiftSymbolType] = [SwiftSymbolType]()
}

class SwiftFunctionType: SwiftSymbolAnyType {
    override var type: SwiftSymbolTypeKind {
        return .function
    }
    
    var returnType: SwiftSymbolType?
    lazy var elements: [SwiftSymbolType] = [SwiftSymbolType]()
}

class SwiftCompositionType: SwiftSymbolAnyType {
    override var type: SwiftSymbolTypeKind {
        return .composition
    }
    
    lazy var elements: [SwiftSymbolType] = [SwiftSymbolType]()
}

class SwiftSomeAnyType: SwiftSymbolAnyType {
    override var type: SwiftSymbolTypeKind {
        return .someAny
    }
    
    var constraints: SwiftSymbolType
    
    init(constraints: SwiftSymbolType) {
        self.constraints = constraints
    }
}
