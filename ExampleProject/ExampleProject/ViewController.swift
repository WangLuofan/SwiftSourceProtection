//
//  ViewController.swift
//  ExampleProject
//
//  Created by 王落凡 on 2026/6/9.
//

import UIKit
import Social
import Dispatch

func globalFunction(_ num: Int) {
    print("\(num)")
}

var globalVariable: String = "123456"

enum TestEnum {
    case first, forth, fifth
    case second(TestA)
    case third
}

enum TestError: Error {
    case specific(Int)
    case generic
}

/// Keychain 错误类型（便于捕获和处理）
enum KeychainError: Error, LocalizedError {
    case saveFailed(status: OSStatus, message: String)
    case readFailed(status: OSStatus, message: String)
    case deleteFailed(status: OSStatus, message: String)
    case dataConversionFailed(message: String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(_, let msg):
            return msg
        case .readFailed(_, let msg):
            return msg
        case .deleteFailed(_, let msg):
            return msg
        case .dataConversionFailed(let msg):
            return msg
        }
    }
}

extension OSStatus {
    var message: String {
        return SecCopyErrorMessageString(self, nil) as String? ?? ""
    }
}


class ViewController: UIViewController {
    
    var u: Int {
        let (a, (s, (c, d))) = (3, (4, (5, 6)))
        
        let i: Int = 3
        let b: Int = 4
        
        return i + b
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        for i in 0..<5 {
            print(i)
        }
        
        let a: (_ x: TestA, _ y: Int) -> Int = { (x: TestA, y: Int) in
            return x.n + y
        }
        
        let b: ((_ x: Int, _ y: Int) -> Int) = { x, y in
            return x - y
        }
        
        let c: (u: Int, v: Int)
        let d: TestA? = TestA(3)
        
        let (k, t) = (3, 4.5)
        
        if let e: Int = d?.testFunc(num1: 3, num2: 4) {
            print(e)
        }
        
        guard let d else {
            return
        }
        d.overC
        
        try? self.testLocalBindings()
        self.testExtraLocalBindings()
        self.testAsyncBindings()
    }
    
    func testLocalBindings() throws {
        let array: [TestEnum] = [.first, .second(TestA(n: 1, z: "ABC"))]
        
        // while let / while case let
        var iterator = array.makeIterator()
        while let element = iterator.next() {
            print(element)
        }
        while case let .second(item) = array.first {
            print(item.n)
            break
        }
        
        // if case / guard case 模式匹配绑定
        if case let .second(value) = array.first {
            print(value.n)
        }
        
        // for case let / for 元组绑定
        for case let .second(node) in array {
            print(node.n)
        }
        for (index, value) in array.enumerated() {
            print(index, value)
        }
        
        // catch 绑定
        do {
            try self.mayThrow()
        } catch let error as NSError {
            print(error.code)
        }
        do {
            try self.mayThrow()
        } catch let otherError {
            print(otherError)
        }
        
        // 闭包捕获列表里的新绑定
        let closure = { [weak self, captured = array.count] in
            print(self as Any, captured)
        }
        closure()
        
        // guard case 绑定
        guard case let .second(last) = array.last else {
            return
        }
        print(last.n)
        
        throw KeychainError.saveFailed(status: errSecUnimplemented, message: "Hello, World")
    }
    
    func testExtraLocalBindings() {
        let optA: Int? = 1
        let optB: Int? = 2
        
        // if let 多重绑定
        if let a = optA, let b = optB {
            print(a, b)
        }
        
        // guard let 多重绑定
        guard let a = optA, let b = optB else {
            return
        }
        print(a, b)
        
        // 同一 let 声明多变量
        let multiA = 1, multiB = 2
        print(multiA, multiB)
        
        // switch case tuple pattern
        let pair = (1, 2)
        switch pair {
            case let (x, y):
                print(x, y)
        }
        
        // catch 枚举关联值绑定
        do {
            try self.mayThrowSpecific()
        } catch TestError.specific(let code) {
            print(code)
        } catch {
            print(error)
        }
        
        // for case let with tuple（可选元组数组）
        let optPairs: [(Int, Int)?] = [(1, 2), nil, (3, 4)]
        for case .some(let (a, b)) in optPairs {
            print(a, b)
        }
    }
    
    func testAsyncBindings() {
        Task {
            async let result = self.fetchValue()
            let value = await result
            print(value)
        }
    }
    
    func mayThrow() throws {
        throw NSError(domain: "test", code: -1)
    }
    
    func mayThrowSpecific() throws {
        throw TestError.specific(42)
    }
    
    func fetchValue() async -> Int {
        return 42
    }
}

class TestA {
    var n: Int
    var k: Double = 1.0
    var z: String = ""
    
    init(_ s: Int) {
        self.n = s
    }
    
    init(n: Int, k: Double = 3.14, z: String = "abc") {
        self.n = n
        self.k = k
        self.z = z
    }
    
    var overC: (u: Int, v: Int) {
        return (3, 4)
    }
    
    func testFunc(num1: Int, num2: Int) -> Int {
        let a: TestEnum = .first
        
        switch a {
            case .first, .forth, .fifth:
                let b = 0
            case .second(let u):
                let c = u.overC
            case .third:
                let t = 0
        }
        
        globalFunction(num1)
        
        return self.testFunc2(num1, num2: num2)
    }
    
    private func testFunc2(_ num1: Int, num2: Int) -> Int {
        let fun: (_ num: Int, _ num2: Int) -> Int = testFunc
        
        let testCls: TestClass = TestClass()
        let roundNum = testCls.testFunc().testFunc2().testFunc().testFunc2().testFunc().dVal.roundDecimals(5)
        
        globalFunction(num2)
        
        return num1 * num2
    }
}

class TestB: TestA {
    override var overC: (k: Int, t: Int) {
        return (4, 5)
    }
}

extension Double {
    func roundDecimals(_ digit: Int = 2) -> Double {
        
        let transformationValue = Double(String(format: "%.\(digit)f", self)) ?? 0
        
        if transformationValue == 0 && self > 0{
            return 1
        }
        
        return transformationValue
    }
}
