//
//  FileHelper.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2025/10/28.
//

import ObjectiveC
import Foundation

class FileHelper {
    public var sourceFiles: [String] = []
    private var excludePaths: [String] = [String]()
    
    init(_ path: String, excludePaths: [String]? = nil) {
        if let excludePaths {
            for excludePath in excludePaths {
                self.excludePaths.append((path as NSString).appendingPathComponent(excludePath))
            }
        }
        
        let dupPath: String = self.prepareForBackup(FileManager.default.currentDirectoryPath)
        
        self.duplicateProject(path, dupPath)
        print("count: \(self.sourceFiles.count)")
    }
}

extension FileHelper {
    private func isPathDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        
        if !fileExists {
            return false
        }
        
        return isDirectory.boolValue
    }
    
    private func shouldTreatASSrouce(_ path: String) -> Bool {
        if (path as NSString).pathExtension.compare("swift", options: .caseInsensitive) != .orderedSame {
            return false
        }

        for excludePath in excludePaths {
            if path.starts(with: excludePath) {
                return false
            }
        }
        
        return true
    }
    
    private func prepareForBackup(_ dstPath: String) -> String {
        let backupPath: String = "\(dstPath)/backup"
        if FileManager.default.fileExists(atPath: backupPath) {
            guard let _ = try? FileManager.default.removeItem(atPath: backupPath) else {
                fatalError("Remove Error")
            }
        }
        
        guard let _ = try? FileManager.default.createDirectory(atPath: backupPath, withIntermediateDirectories: true) else {
            fatalError("Backup Error")
        }
        
        return backupPath
    }
    
    private func duplicateProject(_ srcPath: String, _ dstPath: String) {
        let isDirectory: Bool = self.isPathDirectory(srcPath)
        let lastName = (srcPath as NSString).lastPathComponent
        
        let fileName = "\(dstPath)/\(lastName)"
        
        if !isDirectory {
            try? FileManager.default.copyItem(atPath: srcPath, toPath: fileName)
            
            if self.shouldTreatASSrouce(srcPath) {
                self.sourceFiles.append(srcPath)
            }
            
            return
        }
        
        guard let _ = try? FileManager.default.createDirectory(atPath: fileName, withIntermediateDirectories: true), let files = try? FileManager.default.contentsOfDirectory(atPath: srcPath) else {
            return
        }
        
        files.forEach { file in
            self.duplicateProject((srcPath as NSString).appendingPathComponent(file), (dstPath as NSString).appendingPathComponent(lastName) as String)
        }
    }
}
