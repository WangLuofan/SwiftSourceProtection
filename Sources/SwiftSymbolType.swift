//
//  SwiftSymbolType.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/3/14.
//

enum SwiftSymbolTypeKind {
    case unknown
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
    var isUnknownType: Bool { get }
    
    func isEqualTo(_ symbolType: SwiftSymbolType) -> Bool
}

class SwiftSymbolUnknownType: SwiftSymbolType {
    func isEqualTo(_ symbolType: any SwiftSymbolType) -> Bool {
        return symbolType.isUnknownType
    }
    
    var type: SwiftSymbolTypeKind {
        return .unknown
    }
    
    var isUnknownType: Bool {
        return true
    }
}

class SwiftSymbolAnyType: SwiftSymbolType {
    func isEqualTo(_ symbolType: any SwiftSymbolType) -> Bool {
        if symbolType.type != self.type {
            return false
        }
        
        return true
    }
    
    var type: SwiftSymbolTypeKind {
        return .any
    }
    
    var isUnknownType: Bool {
        return false
    }
}

class SwiftSymbolSingleType: SwiftSymbolAnyType {
    var typeName: String
    
    override func isEqualTo(_ symbolType: any SwiftSymbolType) -> Bool {
        guard super.isEqualTo(symbolType),
            let singleType: SwiftSymbolSingleType = symbolType as? SwiftSymbolSingleType else {
            return false
        }
        
        return singleType.typeName == self.typeName
    }
    
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
    var elementType: any SwiftSymbolType
    
    override func isEqualTo(_ symbolType: any SwiftSymbolType) -> Bool {
        guard super.isEqualTo(symbolType),
              let arrType: SwiftSymbolArrayType = symbolType as? SwiftSymbolArrayType else {
            return false
        }
        
        return arrType.elementType.isEqualTo(self.elementType)
    }
    
    override var type: SwiftSymbolTypeKind {
        return .array
    }
    
    init(elementType: any SwiftSymbolType = SwiftSymbolAnyType()) {
        self.elementType = elementType
    }
}

class SwiftSymbolDictionaryType: SwiftSymbolAnyType {
    var keyType: any SwiftSymbolType
    var valueType: any SwiftSymbolType
    
    override var type: SwiftSymbolTypeKind {
        return .dictionary
    }
    
    init(keyType: any SwiftSymbolType = SwiftSymbolAnyType(), valueType: any SwiftSymbolType = SwiftSymbolAnyType()) {
        self.keyType = keyType
        self.valueType = valueType
    }
    
    override func isEqualTo(_ symbolType: any SwiftSymbolType) -> Bool {
        guard super.isEqualTo(symbolType),
              let dictType: SwiftSymbolDictionaryType = symbolType as? SwiftSymbolDictionaryType else {
            return false
        }
        
        return dictType.keyType.isEqualTo(self.keyType) && dictType.valueType.isEqualTo(self.valueType)
    }
}

class SwiftSymbolTupleType: SwiftSymbolAnyType {
    override var type: SwiftSymbolTypeKind {
        return .tuple
    }
    
    var elements: [any SwiftSymbolType]
    
    override init() {
        self.elements = [any SwiftSymbolType]()
        super.init()
    }
    
    init(elements: [any SwiftSymbolType]) {
        self.elements = elements
        super.init()
    }
    
    override func isEqualTo(_ symbolType: any SwiftSymbolType) -> Bool {
        guard super.isEqualTo(symbolType),
              let tupleType: SwiftSymbolTupleType = symbolType as? SwiftSymbolTupleType else {
            return false
        }
        
        if self.elements.count != tupleType.elements.count {
            return false
        }
        
        for (index, element) in self.elements.enumerated() {
            if !element.isEqualTo(tupleType.elements[index]) {
                return false
            }
        }
        
        return true
    }
}

class SwiftFunctionType: SwiftSymbolAnyType {
    override var type: SwiftSymbolTypeKind {
        return .function
    }
    
    var returnType: (any SwiftSymbolType)?
    var elements: [any SwiftSymbolType]
    
    init(elements: [any SwiftSymbolType], returnType: (any SwiftSymbolType)? = nil) {
        self.returnType = returnType
        self.elements = elements
    }
    
    override init() {
        self.elements = [any SwiftSymbolType]()
        super.init()
    }
    
    override func isEqualTo(_ symbolType: any SwiftSymbolType) -> Bool {
        guard super.isEqualTo(symbolType),
              let funcType: SwiftFunctionType = symbolType as? SwiftFunctionType else {
            return false
        }
        
        let lRetType = self.returnType ?? SwiftSymbolUnknownType()
        let rRetType = funcType.returnType ?? SwiftSymbolUnknownType()
        
        if !lRetType.isEqualTo(rRetType) || self.elements.count != funcType.elements.count {
            return false
        }
        
        for (index, element) in elements.enumerated() {
            if !element.isEqualTo(funcType.elements[index]) {
                return false
            }
        }
        
        return true
    }
}

class SwiftCompositionType: SwiftSymbolAnyType {
    override var type: SwiftSymbolTypeKind {
        return .composition
    }
    
    lazy var elements: [any SwiftSymbolType] = [any SwiftSymbolType]()
    
    override func isEqualTo(_ symbolType: any SwiftSymbolType) -> Bool {
        guard super.isEqualTo(symbolType),
              let compType: SwiftCompositionType = symbolType as? SwiftCompositionType else {
            return false
        }
        
        for (index, element) in elements.enumerated() {
            if !element.isEqualTo(compType.elements[index]) {
                return false
            }
        }
        
        return true
    }
}

class SwiftSomeAnyType: SwiftSymbolAnyType {
    override var type: SwiftSymbolTypeKind {
        return .someAny
    }
    
    var constraints: any SwiftSymbolType
    
    init(constraints: any SwiftSymbolType) {
        self.constraints = constraints
    }
    
    override func isEqualTo(_ symbolType: any SwiftSymbolType) -> Bool {
        guard super.isEqualTo(symbolType),
              let someAnyType: SwiftSomeAnyType = symbolType as? SwiftSomeAnyType else {
            return false
        }
        
        return self.constraints.isEqualTo(someAnyType.constraints)
    }
}
