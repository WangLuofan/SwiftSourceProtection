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
    
    private var schemeInfoProvider: SPSchemeInfoProvider
    private var projectPath: String
    private var argument: SPArgumentProtocol
    
    init(argument: SPArgumentProtocol) {
        self.argument = argument
        self.projectPath = File(path: argument.project).directory
        self.schemeInfoProvider = SPSchemeInfoProvider(project: argument.project, scheme: argument.scheme)
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
        
        var confusedMap: [String: String]? = nil
        if let argument: SPDeObfuseArgument = self.argument as? SPDeObfuseArgument,
           FileManager.default.fileExists(atPath: argument.confusedMap),
           let fileData: Data = try? Data(contentsOf: URL(fileURLWithPath: argument.confusedMap)) {
            confusedMap = try? JSONSerialization.jsonObject(with: fileData) as? [String: String]
        }
        
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
                
                let astCollector: SPSwiftSourceASTCollector = SPSwiftSourceASTCollector(
                    sourceTree: sourceTree,
                    sourceFile: $0,
                    module: module,
                    confusedMap: confusedMap
                )
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
                
                logger.log("--- Associating: \($0.name)")
                astCollector.associate(sourceKit)
            }
        }
        
        for module in modules {
            module.sourceFiles.sorted { $0.path < $1.path }.forEach {
                sourceKit.logger?.log("--- Processing: \($0.name)")
                
                if let sourceTree = sourceTrees[$0.path], let fileScope = fileScopes[$0.path] {
                    let preRewriter: SPSwiftSourceASTPreRewriter = SPSwiftSourceASTPreRewriter(fileScope: fileScope, sourceFile: $0, sourceKit: sourceKit, sourceTree: sourceTree)
                    preRewriter.process()
                }
            }
        }
        
        for module in modules {
            module.sourceFiles.sorted { $0.path < $1.path }.forEach {
                sourceKit.logger?.log("--- Rewriting: \($0.name)")
                
                guard let sourceTree: SourceFileSyntax = sourceTrees[$0.path],
                      let relatedDict: [UInt64: SPSwiftSourceSymbol] = SymbolIndexRelator.shared.get(forFile: $0) else {
                    return
                }
                
                let rewriter: SPSwiftSourceASTRewriter = SPSwiftSourceASTRewriter(
                    sourceTree: sourceTree,
                    sourceFile: $0,
                    relatedDict: relatedDict,
                    confusedMap: confusedMap
                )
                var finalSyntax: SourceFileSyntax = rewriter.rewrite()
                
                if let argument: SPObfuseArgument = self.argument as? SPObfuseArgument,
                    argument.shuffle {
                    let shuffler: SPSwiftSourceASTShuffler = SPSwiftSourceASTShuffler(
                        sourceTree: finalSyntax,
                        sourceFile: $0
                    )
                    
                    sourceKit.logger?.log("--- Shuffling: \($0.name)")
                    finalSyntax = shuffler.shuffle()
                }
                
                if !self.argument.dryRun {
                    try? finalSyntax.description.write(toFile: $0.path, atomically: true, encoding: .utf8)
                } else {
                    print(finalSyntax.description)
                }
            }
        }
        
        let renamer: SPSwiftSourceFileRenamer = SPSwiftSourceFileRenamer(confusedMap: confusedMap)
        for module in modules {
            module.sourceFiles.sorted { $0.path < $1.path }.forEach {
                sourceKit.logger?.log("--- Renaming: \($0)")
                renamer.rename($0)
            }
        }
        
        if let _: SPObfuseArgument = self.argument as? SPObfuseArgument {
            sourceKit.logger?.log("--- Dumping Confused Table")
            ConfuseHelper.dumpConfusedTable(self.projectPath, fileName: "confused.json")
        }
    }
}
