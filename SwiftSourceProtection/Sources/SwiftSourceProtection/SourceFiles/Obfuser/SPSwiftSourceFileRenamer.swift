//
//  SPSwiftSourceFileRenamer.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/7/8.
//

import Foundation
import XcodeProj
import AEXML
import RegexBuilder

class SPSwiftSourceFileRenamer {
    private let projFile: File
    private let schemeName: String
    private let confusedSchemeName: String
    private let confusedMap: [String: String]?
    
    init(projFile: File, scheme: String, confusedMap: [String : String]?) {
        self.schemeName = scheme
        self.confusedSchemeName = ConfuseHelper.confusedSymbolName(scheme, confusedMap: confusedMap)
        self.projFile = projFile
        self.confusedMap = confusedMap
    }
}

extension SPSwiftSourceFileRenamer {
    private func checkCorrectProjectFile(_ projFile: String) -> Bool {
        let process: Process = Process()
        process.executableURL = URL.init(filePath: .init(stringLiteral: "/usr/bin/xcodebuild"))
        
        process.arguments = ["-project", projFile, "-list"]
        
        let pipe: Pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            let output = try pipe.fileHandleForReading.readToEnd()
            
            guard let output,
                  let outputString: String = String(data: output, encoding: .utf8) else {
                print("Failed to retrieve output from Xcode: Unknown Error.")
                return false
            }
            
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else {
                print("Failed to retrieve output from Xcode: \(outputString)")
                return false
            }
            
            let regex = Regex {
                OneOrMore(.whitespace)
                "Schemes:"
                OneOrMore(.newlineSequence)
                OneOrMore(.whitespace)
                Capture {
                    self.schemeName
                }
                Optionally(.newlineSequence)
            }
            
            if let _ = try? regex.firstMatch(in: outputString) {
                return true
            }
        } catch {
            print("Failed to retrieve schemes from Xcode: Unknown Error.: \(error.localizedDescription)")
        }
        
        return false
    }
    
    private func visit(_ element: AEXMLElement, projPath: String) -> String? {
        if element.name == "FileRef",
           let location: String = element.attributes["location"] {
            let startIndex = location.index(location.startIndex, offsetBy: 6)
            let projRelativePath: String = String(location[startIndex...])
            let projFile: String = (projPath as NSString).appendingPathComponent(projRelativePath)
            
            if self.checkCorrectProjectFile(projFile) {
                return projFile
            }
        }
        
        for child in element.children {
            return self.visit(child, projPath: projPath)
        }
        
        return nil
    }
    
    private func parseProjectPathFromWorkspace() -> String? {
        let projPath: String = self.projFile.directory
        
        do {
            guard let wsContentFile: File = self.projFile.appendPathComponent("contents").appendExtension("xcworkspacedata") else {
                return nil
            }
            
            let contentsData: Data = try Data(contentsOf: URL(fileURLWithPath: wsContentFile.path))
            let document: AEXMLDocument = try AEXMLDocument(xml: contentsData)
            
            return self.visit(document.root, projPath: projPath)
        } catch {
            print("Parse Project error: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    private func findProjectPath() -> String? {
        guard self.projFile.extension == "xcworkspace" else {
            return self.projFile.path
        }
        
        return self.parseProjectPathFromWorkspace()
    }
    
    private func renameScheme(_ schemeDir: String) {
        func rename(_ element: AEXMLElement, confusedSchemeName: String) {
            if element.name == "BuildableReference" {
                if let buildableName: String = element.attributes["BuildableName"],
                   buildableName.contains(self.schemeName) {
                    element.attributes["BuildableName"] = buildableName.replacingOccurrences(of: self.schemeName, with: confusedSchemeName)
                }
                
                if let blueprintName: String = element.attributes["BlueprintName"],
                   blueprintName.contains(self.schemeName) {
                    element.attributes["BlueprintName"] = blueprintName.replacingOccurrences(of: self.schemeName, with: confusedSchemeName)
                }
                
                if let container: String = element.attributes["ReferencedContainer"],
                   container.contains(self.schemeName) {
                    element.attributes["ReferencedContainer"] = container.replacingOccurrences(of: self.schemeName, with: confusedSchemeName)
                }
            }
            
            for child in element.children {
                rename(child, confusedSchemeName: confusedSchemeName)
            }
        }
        
        var isDirectory: ObjCBool = ObjCBool(false)
        if FileManager.default.fileExists(atPath: schemeDir, isDirectory: &isDirectory),
           isDirectory.boolValue,
           let schemes: [String] = try? FileManager.default.contentsOfDirectory(atPath: schemeDir) {
            for scheme in schemes {
                guard (scheme as NSString).pathExtension == "xcscheme",
                      (scheme as NSString).deletingPathExtension == self.schemeName else {
                    continue
                }
                
                let schemeFile: String = (schemeDir as NSString).appendingPathComponent(scheme)
                if let confusedShemeFile: String = ((schemeDir as NSString).appendingPathComponent(self.confusedSchemeName) as NSString).appendingPathExtension("xcscheme") {
                    if let schemeData: Data = try? Data(contentsOf: URL(fileURLWithPath: schemeFile)),
                       let document: AEXMLDocument = try? AEXMLDocument(xml: schemeData) {
                        rename(document.root, confusedSchemeName: self.confusedSchemeName)
                        
                        do {
                            try document.xml.write(toFile: schemeFile, atomically: true, encoding: .utf8)
                        } catch {
                            print("Modify scheme failed: \(error.localizedDescription)")
                        }
                    }
                    
                    do {
                        try FileManager.default.moveItem(atPath: schemeFile, toPath: confusedShemeFile)
                    } catch {
                        print("Rename scheme failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func renameProject() {
        guard let projPath: String = self.findProjectPath() else {
            return
        }
        let projDir: String = (projPath as NSString).deletingLastPathComponent
        
        /// 修改scheme
        self.renameScheme((projPath as NSString).appendingPathComponent("xcshareddata/xcschemes"))
        
        /// 修改项目名称
        if FileManager.default.fileExists(atPath: projPath),
           let confusedProject: String = ((projDir as NSString).appendingPathComponent(self.confusedSchemeName) as NSString).appendingPathExtension("xcodeproj") {
            do {
                try FileManager.default.moveItem(atPath: projPath, toPath: confusedProject)
            } catch {
                print("Rename Project Failed: \(error.localizedDescription)")
            }
        }
    }
    
    func renameFile(_ sourceFile: File) {
        guard FileManager.default.fileExists(atPath: sourceFile.path),
              !sourceFile.name.isEmpty,
              !sourceFile.directory.isEmpty,
              let confusedFilePath: String = ((sourceFile.directory as NSString)
                  .appendingPathComponent(ConfuseHelper.confusedSymbolName(sourceFile.nameWithoutExtension, confusedMap: self.confusedMap)) as NSString).appendingPathExtension(sourceFile.extension) else {
            return
        }
        
        do {
            try? FileManager.default.moveItem(atPath: sourceFile.path, toPath: confusedFilePath)
        }
    }
}
