//
//  FileHelper.swift
//  SwiftRefactorUtil
//
//  Created by 王落凡 on 2025/10/28.
//

import ObjectiveC
import Foundation

class FileHelper {
    public var sourceFiles: [String] = []
    private let excludePaths: [String]?
    
    init(_ path: String, excludePaths: [String]? = nil) {
        self.excludePaths = excludePaths
        
        self.listFiles(path)
        print("count: \(self.sourceFiles.count)")
    }
}

extension FileHelper {
    private func listFiles(_ path: String) {
        var isDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        
        if !fileExists {
            return
        }
        
        if !isDirectory.boolValue {
            if (path as NSString).pathExtension.compare("swift", options: .caseInsensitive) == .orderedSame {
                self.sourceFiles.append(path)
            }
            return
        }
        
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: path) else {
            return
        }
        
        files.forEach { file in
            if self.excludePaths?.contains(file) == true {
                return
            }
            
            self.listFiles((path as NSString).appendingPathComponent(file))
        }
    }
}
