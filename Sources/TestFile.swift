class Test2 {
    var test: Test = Test()
    
    init() {
        
    }
}

class Test {
    var test2: Test2 = Test2()
    
    func testFunc() {
        let a = self.test2.test
    }
}
