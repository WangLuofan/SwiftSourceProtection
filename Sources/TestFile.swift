//
//  TestFile.swift
//  SwiftRefactorUtil
//
//  Created by WangLuofan on 2025/10/28.
//

import Foundation

enum TestEnum {
    case One
    case Two
    case Three
}

struct TestStruct {
    
}

/// 第一个测试类
// Hello, World
class TestFile {
    /* test1
     test2
     test3
     */
    private var testProperty: String?
    
    // test2
    private var testProperty2: String?
    
    /// test3
    private var testProperty3: String?
    
    #if DEBUG
    func testDefine() {
        
    }
    #else
    func testDefine(param1: String) {
        
    }
    #endif
}

/// 测试类
class TestFile2 {
    
    static func test() {
        
    }
}

/// 测试类
class TestFile3 {
    
}

extension TestFile {
    private func test1(_ param: String) {
        
    }
}
