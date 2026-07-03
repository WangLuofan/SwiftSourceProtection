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
        
        var sourceTrees: [String: SourceFileSyntax] = [:]
        var fileScopes: [String: SPSwiftSourceScope] = [:]
        var astCollectors: [String: SPSwiftSourceASTCollector] = [:]
        
        let logger: Logger = Logger()
        let sourceKit = SourceKit(logger: Logger())
        
        for module in modules {
            let compilerArguments = SKRequestArray(sourcekitd: sourceKit)
            module.compilerArguments.forEach(compilerArguments.append(_:))
            
            module.sourceFiles.sorted { $0.path < $1.path }.forEach {
                guard let sourceCode: String = try? $0.read() else {
                    return
                }
                
                logger.log("--- Collecting: \($0.name)")
                let sourceTree: SourceFileSyntax = Parser.parse(source: sourceCode)
                
                sourceTrees[$0.path] = sourceTree
                
                let astCollector: SPSwiftSourceASTCollector = SPSwiftSourceASTCollector(sourceTree: sourceTree, sourceFile: $0, module: module)
                let scope: SPSwiftSourceScope = astCollector.walk()
                
                fileScopes[$0.path] = scope
                
                logger.log("--- Indexing: \($0.name)")
                astCollector.index(sourceKit, compilerArguments)
                
                astCollectors[$0.path] = astCollector
            }
            
            module.sourceFiles.sorted { $0.path < $1.path }.forEach {
                guard let astCollector: SPSwiftSourceASTCollector = astCollectors[$0.path] else {
                    return
                }
                
                astCollector.relate(sourceKit)
            }
        }
        
        for module in modules {
            module.sourceFiles.sorted { $0.path < $1.path }.forEach {
                logger.log("--- Processing: \($0.name)")
                
                if let sourceTree = sourceTrees[$0.path], let fileScope = fileScopes[$0.path] {
                    let preRewriter: SPSwiftSourceASTPreRewriter = SPSwiftSourceASTPreRewriter(fileScope: fileScope, sourceFile: $0, sourceKit: sourceKit, sourceTree: sourceTree)
                    preRewriter.process()
                }
            }
        }
        
        for module in modules {
            module.sourceFiles.sorted { $0.path < $1.path }.forEach {
                logger.log("--- Rewriting: \($0.name)")
                
                guard let sourceTree: SourceFileSyntax = sourceTrees[$0.path],
                      let relatedDict: [UInt64: SPSwiftSourceSymbol] = SymbolIndexRelator.shared.get(forFile: $0) else {
                    return
                }
                
                let rewriter: SPSwiftSourceASTRewriter = SPSwiftSourceASTRewriter(
                    sourceTree: sourceTree,
                    sourceFile: $0,
                    relatedDict: relatedDict
                )
                let confusedSyntax: SourceFileSyntax = rewriter.rewrite()
                
                let shuffler: SPSwiftSourceASTShuffler = SPSwiftSourceASTShuffler(
                    sourceTree: confusedSyntax,
                    sourceFile: $0
                )
                let shuffledSyntax: SourceFileSyntax = shuffler.shuffle()
                
                try? shuffledSyntax.description.write(toFile: $0.path, atomically: true, encoding: .utf8)
            }
        }
    }
}
