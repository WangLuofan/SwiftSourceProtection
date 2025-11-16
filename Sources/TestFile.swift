//
//  TestFile.swift
//  SwiftRefactorUtil
//
//  Created by WangLuofan on 2025/10/28.
//

import Foundation

class TestClass {
    
    /// 注释1
    /// 注释3
    private var testProperty: Int = 1
    
    private func testFunc(with firstName: String, _ lastName: String) {
        print("\(firstName): \(lastName)")
    }
    
    private func testFunc2() {
        self.testFunc(with: "Wang", "Luofan")
        self.testProperty = 2
    }
}

extension TestClass {
    
}
