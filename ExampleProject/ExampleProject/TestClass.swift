//
//  TestClass.swift
//  ExampleProject
//
//  Created by WangLuofan on 2026/6/28.
//

class TestClass {
    private var testB = TestClassB()
    
    func testFunc() -> TestClassB {
        return self.testB
    }
}

class TestClassB {
    private var testCls = TestClass()
    var dVal: Double = Double(5)
    
    func testFunc2() -> TestClass {
        return self.testCls
    }
}
