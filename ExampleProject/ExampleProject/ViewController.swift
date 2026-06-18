//
//  ViewController.swift
//  ExampleProject
//
//  Created by 王落凡 on 2026/6/9.
//

import UIKit

enum TestEnum {
    case first
    case second(TestA)
    case third
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
    }
}

class TestA {
    var n: Int
    
    init(s: Int) {
        self.n = s
    }
    
    var c: (u: Int, v: Int) {
        return (3, 4)
    }
    
    func testFunc(num1: Int, num2: Int) -> Int {
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
