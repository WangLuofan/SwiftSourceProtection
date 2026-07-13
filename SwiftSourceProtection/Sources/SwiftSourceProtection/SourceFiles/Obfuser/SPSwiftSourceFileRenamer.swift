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
import PathKit

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
    
    private func modifyScheme(_ xcodeProj: XcodeProj) {
        guard let sharedData: XCSharedData = xcodeProj.sharedData else {
            return
        }
        
        for scheme in sharedData.schemes {
            if scheme.name.contains(self.schemeName) {
                scheme.name = scheme.name.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
            }
            
            if let buildAction = scheme.buildAction {
                for actionEntrties in buildAction.buildActionEntries {
                    if actionEntrties.buildableReference.blueprintName.contains(self.schemeName) {
                        actionEntrties.buildableReference.blueprintName = actionEntrties.buildableReference.blueprintName.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
                    }
                    
                    if actionEntrties.buildableReference.buildableName.contains(self.schemeName) {
                        actionEntrties.buildableReference.buildableName = actionEntrties.buildableReference.buildableName.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
                    }
                    
                    if actionEntrties.buildableReference.referencedContainer.contains(self.schemeName) {
                        actionEntrties.buildableReference.referencedContainer = actionEntrties.buildableReference.referencedContainer.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
                    }
                }
            }
            
            if let profileAction = scheme.profileAction,
               let macroExpansion = profileAction.macroExpansion {
                if macroExpansion.blueprintName.contains(self.schemeName) {
                    macroExpansion.blueprintName = macroExpansion.blueprintName.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
                }
                
                if macroExpansion.buildableName.contains(self.schemeName) {
                    macroExpansion.buildableName = macroExpansion.buildableName.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
                }
                
                if macroExpansion.referencedContainer.contains(self.schemeName) {
                    macroExpansion.referencedContainer = macroExpansion.referencedContainer.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
                }
            }
        }
    }
    
    private func modifyXcodeProj(_ xcodeproj: XcodeProj) -> [String] {
        var groups: [String] = []
        
        xcodeproj.pbxproj.fileReferences.forEach { fileRef in
            if fileRef.path?.contains(self.schemeName) ?? false {
                fileRef.path = fileRef.path?.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
            }
            
            if fileRef.name?.contains(self.schemeName) ?? false {
                fileRef.name = fileRef.name?.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
            }
        }
        
        xcodeproj.pbxproj.nativeTargets.forEach { nativeTarget in
            if nativeTarget.name.contains(self.schemeName) {
                nativeTarget.name = nativeTarget.name.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
            }
            
            if nativeTarget.productName?.contains(self.schemeName) ?? false {
                nativeTarget.productName = nativeTarget.productName?.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
            }
            
            nativeTarget.fileSystemSynchronizedGroups?.forEach { rootGroup in
                if let groupPath: String = rootGroup.path {
                    groups.append(groupPath)
                }
                if rootGroup.path?.contains(self.schemeName) ?? false {
                    rootGroup.path = rootGroup.path?.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
                }
            }
        }
        
        return groups
    }
    
    func renameProject() {
        do {
            guard let projPath: String = self.findProjectPath() else {
                return
            }
            
            let xcodeProjPath: Path = Path(projPath)
            let xcodeProj: XcodeProj = try XcodeProj(path: xcodeProjPath)
            
            /// 修改scheme
            self.modifyScheme(xcodeProj)
            
            /// 修改xcodeproj字段
            let groups: [String] = self.modifyXcodeProj(xcodeProj)
            
            /// 写回数据
            try xcodeProj.write(path: xcodeProjPath, override: true)
            
            /// 修改xcodproj目录名
            if let confusedProjPath: String = (((projPath as NSString).deletingLastPathComponent as NSString).appendingPathComponent(self.confusedSchemeName) as NSString).appendingPathExtension("xcodeproj") {
                try FileManager.default.moveItem(atPath: projPath, toPath: confusedProjPath)
            }
            
            /// 修改文件组
            self.renameFileGroups((projPath as NSString).deletingLastPathComponent, groups)
            
            /// 修改根目录及Podfile
            self.renameRootDirectoryContent(self.projFile.directory)
        } catch {
            print("Rename Project Error: \(error.localizedDescription)")
        }
    }
    
    private func renameFileGroups(_ projPath: String, _ groups: [String]) {
        do {
            for group in groups {
                let groupPath: String = (projPath as NSString).appendingPathComponent(group)
                
                /// 修改文件夹内容
                self.renameGroupContents(groupPath)
                
                /// 修改源代码目录名
                let confusedFolderName: String = ConfuseHelper.confusedSymbolName(group, confusedMap: self.confusedMap)
                let confusedGroupPath: String = (projPath as NSString).appendingPathComponent(confusedFolderName)
                try FileManager.default.moveItem(atPath: groupPath, toPath: confusedGroupPath)
            }
        } catch {
            print("Rename File Group Error: \(error.localizedDescription)")
        }
    }
    
    private func renameGroupContents(_ groupPath: String) {
        do {
            let contents: [String] = try FileManager.default.contentsOfDirectory(atPath: groupPath)
            
            for content in contents {
                var isDirectory: ObjCBool = ObjCBool(false)
                
                let contentPath: String = (groupPath as NSString).appendingPathComponent(content)
                guard FileManager.default.fileExists(atPath: contentPath, isDirectory: &isDirectory) else {
                    continue
                }
                
                if !isDirectory.boolValue && (content as NSString).pathExtension == "swift" {
                    self.renameFile(File(path: contentPath))
                    continue
                }
                
                /// 修改子目录名
                self.renameGroupContents(contentPath)
                
                /// 修改自身名字
                let confusedContentName: String = ConfuseHelper.confusedSymbolName(content, confusedMap: self.confusedMap)
                try FileManager.default.moveItem(atPath: contentPath, toPath: (groupPath as NSString).appendingPathComponent(confusedContentName))
            }
        } catch {
            print("Rename Group Folder Error: \(error.localizedDescription)")
        }
    }
    
    private func renameFile(_ sourceFile: File) {
        guard FileManager.default.fileExists(atPath: sourceFile.path),
              !sourceFile.name.isEmpty,
              !sourceFile.directory.isEmpty,
              let confusedFilePath: String = ((sourceFile.directory as NSString)
                  .appendingPathComponent(ConfuseHelper.confusedSymbolName(sourceFile.nameWithoutExtension, confusedMap: self.confusedMap)) as NSString).appendingPathExtension(sourceFile.extension) else {
            return
        }
        
        do {
            try FileManager.default.moveItem(atPath: sourceFile.path, toPath: confusedFilePath)
        } catch {
            print("Rename Source File Error: \(error.localizedDescription)")
        }
    }
    
    private func renameRootDirectoryContent(_ rootPath: String) {
        do {
            let contents: [String] = try FileManager.default.contentsOfDirectory(atPath: rootPath)
            var isDirectory: ObjCBool = ObjCBool(false)
            
            for content in contents {
                guard FileManager.default.fileExists(atPath: (rootPath as NSString).appendingPathComponent(content), isDirectory: &isDirectory) else {
                    continue
                }
                
                if isDirectory.boolValue,
                   content == self.schemeName {
                    try FileManager.default.moveItem(atPath: (rootPath as NSString).appendingPathComponent(content), toPath: (rootPath as NSString).appendingPathComponent(self.confusedSchemeName))
                    continue
                }
                
                if !isDirectory.boolValue,
                   content == "Podfile" || content == "podfile" {
                    self.modifyPodfileContent((rootPath as NSString).appendingPathComponent(content))
                    continue
                }
            }
            
        } catch {
            print("Rename Root Content Error: \(error.localizedDescription)")
        }
    }
    
    private func modifyPodfileContent(_ filePath: String) {
        do {
            guard FileManager.default.fileExists(atPath: filePath) else {
                return
            }
            
            let Podfile: File = File(path: filePath)
            var podFileContent: [String] = try Podfile.read().components(separatedBy: "\n")
            
            let targetRegex: Regex = Regex {
                ZeroOrMore(.whitespace)
                "target"
                ZeroOrMore(.whitespace)
                Capture {
                    "'\(self.schemeName)'"
                }
            }
            
            let projectRegex: Regex = Regex {
                ZeroOrMore(.whitespace)
                "project"
                ZeroOrMore(.whitespace)
                Capture {
                    "'\(self.schemeName)"
                }
            }
            
            /// 替换target/project
            for (index, line) in podFileContent.enumerated() {
                if let _ = try targetRegex.firstMatch(in: line) {
                    podFileContent[index] = line.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
                    continue
                }
                
                if let _ = try projectRegex.firstMatch(in: line) {
                    podFileContent[index] = line.replacingOccurrences(of: self.schemeName, with: self.confusedSchemeName)
                    continue
                }
            }
            
            /// 写回文件
            try podFileContent.joined(separator: "\n").write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("Modify Podfile Error: \(error.localizedDescription)")
        }
    }
}
