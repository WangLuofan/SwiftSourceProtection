//
//  SwiftSourceClassInfo.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/12/12.
//

class SwiftSourceClassInfo: SwiftSourceBaseInfo {
    
    lazy var superClasses: [String] = []
    
    init() {
        super.init(sourcetype: .Class)
    }
    
    override init(sourcetype: SwiftSourceType) {
        super.init(sourcetype: sourcetype)
    }
}
