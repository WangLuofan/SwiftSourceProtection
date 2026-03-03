nonisolated(unsafe) let myCls: MyClass = MyClass.init(memberVar: 3)
nonisolated(unsafe) let b: [String: MyClass] = [String: MyClass]()
nonisolated(unsafe) let a: [MyClass] = [MyClass]()

enum TestEnum {
    case test1, test2(MyClass), test3, test4
}

protocol MyClassProtocol {
    func testProtocolFunc() -> MyClass
}

// 全局变量 - 应该收集
let globalConstant = 10
nonisolated(unsafe) var globalVariable: String = "test"

// 全局函数 - 应该收集
func globalFunction() -> MyClass {
    return MyClass()
}

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
        let myCls: MyClass = MyClass.init(memberVar: 3)
        let myCls2: MyClass = MyClass.init(memberVar: 3)
        let myCls3: MyClass = MyClass.init(memberVar: 3)
        let myCls4: MyClass = MyClass.init(memberVar: 3)
        
        let a = [myCls, myCls2, myCls3, myCls4]
        
        for (index, cls) in a.enumerated() {
            
        }
        
        let closure: ((_ cls: MyClass) -> MyClass?) = { [weak self, weak myCls] cls in
            MyClass()
        }
        
        // 局部变量 - 不应该收集
        let localVar = 5
        
        // 局部函数 - 不应该收集
        func localFunction(num: Int, str s: String) {
            let test: MyClass? = MyClass(memberVar: 3)
            let a: Int? = 3
            
            if let test: MyClass = test {
                test.memberVar
            }
            
            let t = s + "World"
            let b = TestEnum.test1
            
            switch b {
            case .test1:
                break
            case .test2(let b):
                break
            case .test3:
                break
            case .test4:
                break
            default:
                break
            }
        }
        
        // 待处理
        localFunction(num: 3, str: "Hello")
    }
    
    func testMemberMethod() {
        self.memberMethod(num: 3)
    }
}
