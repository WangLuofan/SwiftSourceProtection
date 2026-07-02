//
//  SPSwiftSourceEnumCaseSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/18.
//

import SwiftSyntax

class SPSwiftSourceEnumCaseSymbol: SPSwiftSourceFunctionSymbol {
    override init(sourceFile: File, signature: String, symbolScope: SymbolScope, sourceLocation: SourceLocation) {
        super.init(sourceFile: sourceFile, signature: signature, symbolScope: symbolScope, nodeKind: .enumCase, sourceLocation: sourceLocation)
    }
}
