//
//  SPSwiftSourceEnumCaseSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/18.
//

import SwiftSyntax

class SPSwiftSourceEnumCaseSymbol: SPSwiftSourceSymbol {
    lazy var relatedType: [String] = []
    
    init(sourceFile: File, symbolScope: SymbolScope, sourceLocation: SourceLocation) {
        super.init(sourceFile: sourceFile, symbolScope: symbolScope, nodeKind: .enumCase, sourceLocation: sourceLocation)
    }
}
