//
//  ViewController.swift
//  ExampleProject
//
//  Created by 王落凡 on 2026/6/9.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        for i in 0..<5 {
            print(i)
        }
        
        let a: ((_ x: Int, _ y: Int) -> Int) = { (x: Int, y: Int) in
            return x + y
        }
        
        let b: ((_ x: Int, _ y: Int) -> Int) = { x, y in
            return x - y
        }
    }
}

