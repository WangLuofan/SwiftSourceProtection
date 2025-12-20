//
//  TestFile.swift
//  SwiftRefactorUtil
//
//  Created by WangLuofan on 2025/10/28.
//

import Foundation

func globalFunction(test: String) {
    
}

protocol TestProtocol {
    
}

class TestClass2 {
    var testOverride: Int {
        return 0
    }
    
    var (num , text: String) = (1, "Hello")
}

class TestClass3: TestClass2, TestProtocol {
    override var testOverride: Int {
        return 3
    }
}

class TestClass: NSObject {
    
    /// 注释1
    /// 注释3
    private var testProperty: Int = 1
    private var testClosure: ((_ userName: String, _ userAge: Int, _ userEmail: String) -> Void)?
    static let testStatic: Int = 0
    
    private func testFunc(with firstName: String, _ lastName: String) {
        print("\(firstName): \(lastName)")
        
        self.testClosure = { [weak self] userName, userAge, userEmail in
            print("\(userName)-\(userAge)-\(userEmail)")
        }
        
//        let test2: TestClass2 = TestClass2()
//        let closure: ((_ text: String, _ name: String) -> Void) = { [weak self, weak test2] text, name in
//            print("\(text)")
//        }
    }
    
    private func testFunc2() {
        self.testFunc(with: "Wang", "Luofan")
        self.testProperty = 2
    }
}

extension TestClass {
    
}
