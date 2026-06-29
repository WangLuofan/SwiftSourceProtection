//
//  IndexStore.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/22.
//

import sourcekitd
import SwiftSyntax

class IndexStore {
    static let indexStore: IndexStore = IndexStore()
    
    private var fileForUSR: [String: File] = [:]
    private var symbolForUSR: [String: SPSwiftSourceSymbol] = [:]
    private var response: [String: SKResponseDictionary] = [:]
    private var refForFile: [File: [String: [SKResponseDictionary]]] = [:]
    private var scopeForNode: [File: [UInt64: SPSwiftSourceScope]] = [:]
    private var fileForIndexStore: [File: SKResponseDictionary] = [:]
}

extension IndexStore {
    func set(usr: String, forSymbol: SPSwiftSourceSymbol) {
        self.symbolForUSR[usr] = forSymbol
    }
    
    func getSymbol(usr: String) -> SPSwiftSourceSymbol? {
        return self.symbolForUSR[usr]
    }
    
    func set(usr: String, toFile: File) {
        self.fileForUSR[usr] = toFile
    }
    
    func getFile(usr: String) -> File? {
        return self.fileForUSR[usr]
    }
    
    func set(resp: SKResponseDictionary, toUSR: String) {
        self.response[toUSR] = resp
    }
    
    func getResponse(usr: String) -> SKResponseDictionary? {
        return self.response[usr]
    }
    
    func set(line: Int, col: Int, ref: SKResponseDictionary, toFile: File) {
        let uniqueID: String = "\(line):\(col)"
        self.refForFile[toFile, default:[:]][uniqueID, default: []].append(ref)
    }
    
    func getRef(fromFile file: File, line: Int, col: Int) -> [SKResponseDictionary]? {
        let uniqueID: String = "\(line):\(col)"
        return self.refForFile[file]?[uniqueID]
    }
    
    func set(nodeID: UInt64, _ scope: SPSwiftSourceScope, inFile file: File) {
        self.scopeForNode[file, default:[:]][nodeID] = scope
    }
    
    func set(resp: SKResponseDictionary, toFile file: File) {
        self.fileForIndexStore[file] = resp
    }
    
    func getResponse(forFile file: File) -> SKResponseDictionary? {
        return self.fileForIndexStore[file]
    }
    
    func scope(token: TokenSyntax, inFile file: File) -> SPSwiftSourceScope? {
        guard let scopes = self.scopeForNode[file] else { return nil }
        
        var node: Syntax? = token.parent
        while let current = node {
            if let scope = scopes[current.id.indexInTree.toOpaque()] {
                return scope
            }
            
            node = current.parent
        }
        return nil
    }
}
