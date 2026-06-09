//
//  SPSwiftSourceClassSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

class SPSwiftSourceClassSymbol: SPSwiftSourceSymbol {
    init(sourceFile: File) {
        super.init(sourceFile: sourceFile, nodeKind: .class)
    }
}
