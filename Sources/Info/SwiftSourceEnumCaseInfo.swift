//
//  SwiftSourceEnumCaseInfo.swift
//  SwiftSourceProtection
//
//  Created by wangluofan on 2026/1/10.
//

class SwiftSourceEnumCaseInfo: SwiftSourceBaseInfo {
    lazy var itemParamTypes: [String] = [String]()
    
    init() {
        super.init(sourcetype: .EnumCase)
    }
}
