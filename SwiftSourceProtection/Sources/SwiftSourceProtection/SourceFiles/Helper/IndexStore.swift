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
}
