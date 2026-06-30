//
//  SymbolIndexRelator.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/30.
//

class SymbolIndexRelator {
    static let shared: SymbolIndexRelator = SymbolIndexRelator()
    
    private var relatedDict: [File: [UInt64: SPSwiftSourceSymbol]] = [:]
    
    func set(symbol: SPSwiftSourceSymbol, index: UInt64, forFile file: File) {
        self.relatedDict[file, default: [:]][index] = symbol
    }
    
    func get(forFile file: File) -> [UInt64: SPSwiftSourceSymbol]? {
        return self.relatedDict[file]
    }
}
