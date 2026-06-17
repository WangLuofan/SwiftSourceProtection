//
//  SPSwiftSourceVariableSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

class SPSwiftSourceVariableSymbol: SPSwiftSourceSymbol {
    var accessLevel: AccessLevel = .internal
    
    var isStaticSymbol: Bool = false
    
    override init(sourceFile: File, symbolScope: SymbolScope, nodeKind: NodeKind = .variable) {
        super.init(sourceFile: sourceFile, symbolScope: symbolScope, nodeKind: nodeKind)
    }
}
