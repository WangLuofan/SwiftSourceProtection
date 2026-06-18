//
//  SPSwiftSourceClassSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

class SPSwiftSourceClassSymbol: SPSwiftSourceSymbol {
    var children: [SPSwiftSourceSymbol] = []
    
    init(sourceFile: File, symbolScope: SymbolScope) {
        super.init(sourceFile: sourceFile, symbolScope: symbolScope, nodeKind: .class)
    }
    
    override init(sourceFile: File, symbolScope: SymbolScope, nodeKind: NodeKind) {
        super.init(sourceFile: sourceFile, symbolScope: symbolScope, nodeKind: nodeKind)
    }
}
