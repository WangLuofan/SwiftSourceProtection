// 全局变量 - 应该收集
let globalConstant = 10
nonisolated(unsafe) var globalVariable: String = "test"

// 全局函数 - 应该收集
func globalFunction() {}

class MyClass {
    // 成员变量 - 应该收集
    var memberVar: Int = 0
    
    // 成员方法 - 应该收集
    func memberMethod() {
        
        // 局部变量 - 不应该收集
        let localVar = 5
        
        // 局部函数 - 不应该收集
        func localFunction(num: Int) {
            let test: MyClass? = MyClass()
            let a: Int? = 3
            
            guard let test = a else{
                return
            }
        }
    }
}
