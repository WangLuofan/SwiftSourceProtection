//
//  SPSwiftSourceEnumCaseSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/18.
//

class SPSwiftSourceEnumCaseSymbol: SPSwiftSourceSymbol {
    lazy var relatedType: [String] = []
    
    init(sourceFile: File, symbolScope: SymbolScope) {
        super.init(sourceFile: sourceFile, symbolScope: symbolScope, nodeKind: .enumCase)
    }
}
