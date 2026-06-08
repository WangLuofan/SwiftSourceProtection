//
//  SPSourceProtection.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/1.
//

import Foundation
import SwiftSyntax
import SwiftParser
import SwiftOperators

class SPSourceProtection {
    
    var schemeInfoProvider: SPSchemeInfoProvider
    
    init(project: String, scheme: String) {
        self.schemeInfoProvider = SPSchemeInfoProvider(project: project, scheme: scheme)
    }
    
    func run() {
        guard let modules: [Module] = self.schemeInfoProvider.getModulesFromProject() else {
            return
        }
        
        for module in modules {
            module.sourceFiles.sorted { $0.path < $1.path }.forEach {
                guard let sourceCode: String = try? $0.read() else {
                    return
                }
                
                print("--- Collection: \($0.name)")
                let sourceTree: SourceFileSyntax = Parser.parse(source: sourceCode)
                let foldedSourceTree: SourceFileSyntax? = try? OperatorTable.standardOperators.foldAll(sourceTree).cast(SourceFileSyntax.self)
                
                let astCollector: SPSwiftSourceASTCollector = SPSwiftSourceASTCollector(sourceTree: foldedSourceTree ?? sourceTree, sourceFile: $0)
                astCollector.walk()
                
                print("--- Indexing: \($0.name)")
            }
        }
    }
}
