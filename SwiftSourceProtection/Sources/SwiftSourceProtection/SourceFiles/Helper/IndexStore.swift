//
//  IndexStore.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/22.
//

import sourcekitd

class IndexStore {
    static let indexStore: IndexStore = IndexStore()
    
    private var fileForUSR: [String: File] = [:]
    private var symbolForUSR: [String: SPSwiftSourceSymbol] = [:]
    private var response: [String: SKResponseDictionary] = [:]
    private var refForFile: [File: [[String: SKResponseDictionary]]] = [:]
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
        let fileLine: String = String(line)
        let fileCol: String = String(col)
        
        self.refForFile[toFile, default:[]].append([fileLine + fileCol: ref])
    }
    
    func getRef(fromFile file: File, line: Int, col: Int) -> SKResponseDictionary? {
        let fileLine: String = String(line)
        let fileCol: String = String(col)
        
        guard let fileRefData: [[String: SKResponseDictionary]] = self.refForFile[file] else {
            return nil
        }
        
        for data in fileRefData {
            if let ref = data[fileLine + fileCol] {
                return ref
            }
        }
        
        return nil
    }
}
