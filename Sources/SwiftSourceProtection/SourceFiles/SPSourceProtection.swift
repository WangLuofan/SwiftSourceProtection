//
//  SPSourceProtection.swift
//  SwiftSourceProtection
//
//  Created by 王落凡 on 2026/6/1.
//

class SPSourceProtection {
    
    var schemeInfoProvider: SPSchemeInfoProvider
    
    init(project: String, scheme: String) {
        self.schemeInfoProvider = SPSchemeInfoProvider(project: project, scheme: scheme)
    }
    
    func run() {
        guard let modules: [Module] = self.schemeInfoProvider.getModulesFromProject() else {
            return
        }
        
        
    }
}
