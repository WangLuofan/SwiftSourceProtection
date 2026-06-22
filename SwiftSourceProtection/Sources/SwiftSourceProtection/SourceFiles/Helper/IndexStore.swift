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
    private var response: [String: SKResponseDictionary] = [:]
}

extension IndexStore {
    func set(usr: String, toFile: File) {
        self.fileForUSR[usr] = toFile
    }
    
    func set(resp: SKResponseDictionary, toUSR: String) {
        self.response[toUSR] = resp
    }
}
