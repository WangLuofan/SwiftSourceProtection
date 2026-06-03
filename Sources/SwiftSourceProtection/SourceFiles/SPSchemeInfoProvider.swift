//
//  SPSchemeInfoProvider.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/2.
//

import Foundation

class SPSchemeInfoProvider {
    var project: String
    var scheme: String
    
    private var isWorkspace: Bool = false
    
    private typealias MutableModuleData = (source: [File], plists: [File], args: [String], order: Int)
    private typealias MutableModuleDictionary = [String: MutableModuleData]
    
    init(project: String, scheme: String) {
        self.project = project
        self.scheme = scheme
        
        
        if project.hasSuffix(".xcworkspace") {
            self.isWorkspace = true
        }
    }
    
    func getModulesFromProject() -> [Module]? {
        if !self.checkXcode() {
            print("Cannot find Xcode.")
            return nil
        }
        
        let process: Process = Process()
        process.executableURL = URL.init(filePath: .init(stringLiteral: "/usr/bin/xcodebuild"))
        
        let projectParameter = self.isWorkspace ? "-workspace" : "-project"
        process.arguments = ["-scheme", self.scheme, projectParameter, self.project, "-sdk", "iphonesimulator", "clean", "build"]
        
        let pipe: Pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            print("Building Project...")
            
            try process.run()
            let output = try pipe.fileHandleForReading.readToEnd()
            
            process.waitUntilExit()
            
            guard process.terminationStatus == 0,
                  let output,
                  let outputString: String = String(data: output, encoding: .utf8) else {
                print("Failed to retrieve output from Xcode.")
                return nil
            }
            
            return self.parseModuleFromOutput(outputString)
        } catch {
            print("Unexpected Error When Build Project")
        }
        
        return nil
    }
    
    private func checkXcode() -> Bool {
        let process: Process = Process()
        process.executableURL = URL.init(filePath: .init(stringLiteral: "/usr/bin/xcode-select"))
        process.arguments = ["-p"]
        
        let pipe: Pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                return false
            }
        } catch {
            return false
        }
        
        return true
    }
    
    private func parseModuleFromOutput(_ output: String) -> [Module] {
        let outputComps: [String] = output.components(separatedBy: "\n")
        var modules: MutableModuleDictionary = [:]
        for (_, line) in outputComps.enumerated() {
            if let moduleName = firstMatch(for: "(?<=-module-name ).*?(?= )", in: line) {
                self.parseMergeSwiftModulePhase(line: line, moduleName: moduleName, modules: &modules)
            }
        }
        
        return modules.sorted { $0.value.order < $1.value.order }.map {
            Module(name: $0.key,
                   sourceFiles: Set($0.value.source),
                   compilerArguments: $0.value.args)
        }
    }
    
    private func parseMergeSwiftModulePhase(line: String, moduleName: String, modules: inout MutableModuleDictionary) {
        guard modules[moduleName]?.args.isEmpty != false else {
            return
        }
        
        guard var fullRelevantArguments = firstMatch(for: "/usr/bin/swiftc.*-module-name \(moduleName) .*", in: line) else {
            return
        }
        
        var swiftFileList: File?
        let result = fullRelevantArguments.match(regex: "(?<=@).*SwiftFileList")
        
        if let pathRange = result.first?.range {
            let nsStr: NSString = fullRelevantArguments as NSString
            swiftFileList = File(path: nsStr.substring(with: pathRange))
            
            let fullRange: NSRange = NSMakeRange(pathRange.location - 1, pathRange.length + 1)
            fullRelevantArguments = nsStr.replacingCharacters(in: fullRange, with: "")
        }
        
        let relevantArguments = fullRelevantArguments.replacingEscapedSpaces
            .components(separatedBy: " ")
            .map { $0.removingPlaceholder }
        var compilerArguments = parseCompilerArguments(from: relevantArguments)
        
        var files: [File]
        if let swiftFileList {
            do {
                let swiftFilePaths = try swiftFileList.read()
                    .components(separatedBy: "\n")
                    .filter { !$0.isEmpty }
                    .map{ $0.removeEscapedSpaces }
                
                if let complieFlagIndex = compilerArguments.firstIndex(of: "-c") {
                    var insertIndex = complieFlagIndex
                    if complieFlagIndex + 1 < compilerArguments.count,
                        compilerArguments[complieFlagIndex + 1].hasPrefix("-j") {
                        insertIndex += 1
                    }

                    compilerArguments.insert(contentsOf: swiftFilePaths, at: insertIndex + 1)
                } else {
                    compilerArguments.append(contentsOf: ["-c"] + swiftFilePaths)
                }

                files = swiftFilePaths.map(File.init)
            } catch {
                return
            }
        } else {
            files = parseModuleFiles(from: relevantArguments)
        }
        
        set(sourceFiles: files, to: moduleName, modules: &modules)
        set(compilerArgs: compilerArguments, to: moduleName, modules: &modules)
    }
    
    private func parseCompilerArguments(from relevantArguments: [String]) -> [String] {
        var args: [String?] = Array(relevantArguments.dropFirst())
        while let indexOfOutputMap = args.firstIndex(of: "-output-file-map") {
            args[indexOfOutputMap] = nil
            args[indexOfOutputMap + 1] = nil
        }
        let forbiddenArgs = ["-parseable-output", "-incremental", "-serialize-diagnostics", "-emit-dependencies", "-enforce-exclusivity\\=checked"]
        for (index, arg) in args.enumerated() {
            if forbiddenArgs.contains(arg ?? "") {
                args[index] = nil
            } else if arg == "-O" {
                args[index] = "-Onone"
            } else if arg == "-DNDEBUG=1" {
                args[index] = "-DDEBUG=1"
            } else if arg == "-DDEBUG\\=1" {
                args[index] = "-DDEBUG=1"
            }
        }
        args.append(contentsOf: ["-D", "DEBUG"])
        return args.compactMap { $0 }
    }
    
    private func parseModuleFiles(from relevantArguments: [String]) -> [File] {
        var files: [File] = []
        var fileZone: Bool = false
        for arg in relevantArguments {
            if fileZone {
                if arg.hasPrefix("/") {
                    let file = File(path: arg)
                    files.append(file)
                }
                fileZone = arg.hasPrefix("-") == false || files.count == 0
            } else {
                fileZone = arg == "-c"
            }
        }
        return files
    }
}

extension SPSchemeInfoProvider {
    private func set(sourceFiles: [File], to moduleName: String, modules: inout MutableModuleDictionary) {
        registerFoundModuleIfNeeded(moduleName, modules: &modules)
        modules[moduleName]?.source = sourceFiles
    }
    
    private func set(compilerArgs: [String], to moduleName: String, modules: inout MutableModuleDictionary) {
        registerFoundModuleIfNeeded(moduleName, modules: &modules)
        modules[moduleName]?.args = compilerArgs
    }

    private func registerFoundModuleIfNeeded(_ moduleName: String, modules: inout MutableModuleDictionary) {
        guard modules[moduleName] == nil else {
            return
        }
        let moduleData: MutableModuleData = ([], [], [], modules.count)
        modules[moduleName] = moduleData
    }
}
