class Test2 {
    static func test() -> Test.Type {
        return Test.self
    }
}

class Test {
    static func test2() -> Test2.Type {
        return Test2.self
    }
    
    static func test() {
        let t = Test.test2().test().test2().test().test()
    }
}
