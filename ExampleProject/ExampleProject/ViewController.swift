//
//  ViewController.swift
//  ExampleProject
//
//  Created by 王落凡 on 2026/6/9.
//

import UIKit

enum TestEnum {
    case first, forth, fifth
    case second(TestA)
    case third
}

enum TestError: Error {
    case specific(Int)
    case generic
}

class ViewController: UIViewController {

    var u: Int {
        let (a, (s, (c, d))) = (3, (4, (5, 6)))

        let i: Int = 3
        let b: Int = 4

        return i + b
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        for i in 0..<5 {
            print(i)
        }

        let a: (_ x: Int, _ y: Int) -> Int = { (x: Int, y: Int) in
            return x + y
        }

        let b: ((_ x: Int, _ y: Int) -> Int) = { x, y in
            return x - y
        }

        let c: (u: Int, v: Int)
        let d: TestA? = TestA(s: 3)

        let (k, t) = (3, 4.5)

        if let e: Int = d?.testFunc(num1: 3, num2: 4) {
            print(e)
        }

        guard let d else {
            return
        }
        d.c

        self.testLocalBindings()
        self.testExtraLocalBindings()
        self.testAsyncBindings()
    }

    func testLocalBindings() {
        let array: [TestEnum] = [.first, .second(TestA(s: 1))]

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

    init(s: Int) {
        self.n = s
    }

    init(_ s: Int) {
        self.n = s
    }

    var c: (u: Int, v: Int) {
        return (3, 4)
    }

    func testFunc(num1: Int, num2: Int) -> Int {
        let a: TestEnum = .first

        switch a {
        case .first, .forth, .fifth:
            let b = 0
        case .second(let u):
            let c = u.c
        case .third:
            let t = 0
        }

        return self.testFunc(num1, num2: num2)
    }

    private func testFunc(_ num1: Int, num2: Int) -> Int {
        return num1 * num2
    }
}

class TestB: TestA {
    override var c: (k: Int, t: Int) {
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
