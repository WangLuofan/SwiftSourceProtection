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
    private var projectFile: File
    private var argument: SPArgumentProtocol
    
    init(argument: SPArgumentProtocol) {
        self.argument = argument
        self.projectFile = File(path: argument.project)
        self.schemeInfoProvider = SPSchemeInfoProvider(project: argument.project, scheme: argument.scheme)
    }
    
    private func generateDecrypted(_ sourceFiles: Set<File>) -> String? {
        let encryptedKeyBytes: UInt8 = UInt8.random(in: UInt8.min...UInt8.max)
        
        let encryptedKey: String = String(format: "0x%02X", encryptedKeyBytes)
        if let encryptedPath: String = sourceFiles.randomElement()?.directory {
            let fileURL: URL = URL(fileURLWithPath: (encryptedPath as NSString).appendingPathComponent("StringHelper.swift"))
            let sourceCode = SPSwiftSourceASTBuilder().buildDecryptedFunctionWithKey(encryptedKey)
            
            if !FileManager.default.fileExists(atPath: fileURL.path()) {
                if FileManager.default.createFile(atPath: fileURL.path(), contents: nil) == false {
                    print("SourceCode Generate Error.")
                    return nil
                }
            }
            
            do {
                let handle = try FileHandle(forWritingTo: fileURL)
                try handle.seekToEnd()
                try handle.write(contentsOf: sourceCode.formatted().description.data(using: .utf8)!)
                try handle.close()
                
                return encryptedKey
            } catch {
                print("SourceCode Generate Error.: \(error.localizedDescription)")
            }
        }
        
        return nil
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
            let encryptedKey: String? = (confusedMap == nil ? self.generateDecrypted(module.sourceFiles) : nil)
            module.sourceFiles.sorted { $0.path < $1.path }.forEach {
                sourceKit.logger?.log("--- Rewriting: \($0.name)")
                
                guard let sourceTree: SourceFileSyntax = sourceTrees[$0.path],
                      let relatedDict: [UInt64: SPSwiftSourceSymbol] = SymbolIndexRelator.shared.get(forFile: $0) else {
                    return
                }
                
                let rewriter: SPSwiftSourceASTRewriter = SPSwiftSourceASTRewriter(
                    sourceTree: sourceTree,
                    sourceFile: $0,
                    encryptedKey: encryptedKey,
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
        
        if self.argument.rename {
            let renamer: SPSwiftSourceFileRenamer = SPSwiftSourceFileRenamer(
                projFile: self.projectFile,
                scheme: self.argument.scheme,
                confusedMap: confusedMap
            )
            
            renamer.renameProject()
            for module in modules {
                module.sourceFiles.sorted { $0.path < $1.path }.forEach {
                    sourceKit.logger?.log("--- Renaming: \($0.name)")
                    renamer.renameFile($0)
                }
            }
        }
        
        if let _: SPObfuseArgument = self.argument as? SPObfuseArgument {
            sourceKit.logger?.log("--- Dumping Confused Table")
            ConfuseHelper.dumpConfusedTable(self.projectFile.directory, fileName: "confused.json")
        }
    }
}
