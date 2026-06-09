//
//  SPSwiftSourceSymbol.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/8.
//

import Foundation
import SwiftSyntax

class SPSwiftSourceSymbol {
    var sourceFile: File
    
    var nodeKind: SPSwiftSourceNodeKind
    
    var originalSymbolName: String?
    
    var confusedSymbolName: String?
    
    var ASTNode: SyntaxProtocol?
    
    init(sourceFile: File, nodeKind: SPSwiftSourceNodeKind) {
        self.sourceFile = sourceFile
        self.nodeKind = nodeKind
    }
}
