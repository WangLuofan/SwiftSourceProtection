class MyClass {
    // 成员变量 - 应该收集
    var memberVar: Int = 0
    
    init() {
        self.memberVar = 0
    }
    
    init(memberVar: Int) {
        self.memberVar = memberVar
    }
    
    init(_ memberVar: Int) {
        self.memberVar = memberVar
    }
    
    // 成员方法 - 应该收集
    func memberMethod(num: Int) {
        let myCls: MyClass = MyClass(memberVar: 3)
    }
}
