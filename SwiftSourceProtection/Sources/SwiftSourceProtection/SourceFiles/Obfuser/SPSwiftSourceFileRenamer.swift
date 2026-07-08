//
//  SPSwiftSourceFileRenamer.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/7/8.
//

import Foundation

class SPSwiftSourceFileRenamer {
    private let confusedMap: [String: String]?
    
    init(confusedMap: [String : String]?) {
        self.confusedMap = confusedMap
    }
}

extension SPSwiftSourceFileRenamer {
    func rename(_ sourceFile: File) {
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
