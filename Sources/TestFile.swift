//
//  TestFile.swift
//  SwiftSourceProtection
//
//  Created by WangLuofan on 2025/10/28.
//

import Foundation
import AuthenticationServices
import Accounts
import WeatherKit
import WeatherKit

class ABC {
    lazy var testLazy: String = {
        let testLazy: String = "TestLazy"
        return testLazy
    }()
}

enum TestEnum {
    case First
    case Second
}

func globalFunction(test: String) {
    let test: TestEnum = .First
    switch test {
    case .First:
        print("hello")
    case .Second:
        print("world")
    }
    
    for i in 0..<10 {
        let i = 0
    }
    
    let optStr: String? = "Hello"
    if let optStr {
        print("OK")
    }
}

protocol TestProtocol {
    
}

class TestClass2 {
    var testOverride: Int {
        return 0
    }
    
    func testOverrideFunc() {
        globalFunction(test: "Hello")
    }
}

class TestClass3: TestClass2, TestProtocol {
    override var testOverride: Int {
        return 3
    }
    
    override func testOverrideFunc() {
        let i = 0
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
        let testHello = "Hello, World"
        
        self.testFunc(with: "Wang", "Luofan")
        self.testProperty = 2
    }
}

extension TestClass {
    
}
