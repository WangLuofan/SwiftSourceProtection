
//
//  SwiftASTSyntaxRewriter.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/2/6.
//

import Foundation
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

class SwiftASTSyntaxRewriter: SyntaxRewriter {
    private let sourceFile: String
    private var switchExprStack: [SwitchExprSyntax] = [SwitchExprSyntax]()
    
    init(sourceFile: String) {
        self.sourceFile = sourceFile
        super.init(viewMode: .sourceAccurate)
    }
}
