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
    }
}

class TestA {
    var c: (u: Int, v: Int) {
        return (3, 4)
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
