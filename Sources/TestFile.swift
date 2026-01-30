class Test2 {
    var test: Test = Test()
    
//    func test() -> Test {
//        return Test()
//    }
    
    init() {
        
    }
    
    func testInt() -> Int {
        return 4
    }
}

class Test {
    func test() -> Test2 {
        return Test2()
    }
    
    func testFunc() {
        let a = self.test().test.test().test.test()
    }
}
