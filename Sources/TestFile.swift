
//func TestEnumFunc() {
//    let text = 123
//    let first = TestEnum.first(3)
//    switch first {
//    case .first(let num):
//        print(num)
//    case .second(let str):
//        print(str)
//    case .third(let str1, let str2):
//        print(str1 + str2)
//    case .forth:
//        print("None")
//    }
//}
//
//enum TestEnum {
//    case first(Int)
//    case second(String)
//    case third(String, String), forth
//    
//    func test() {
//        
//    }
//}

class Test1 {
    var testNum: Int = 0
    var testString: String = ""
    
    func testFunc(_ num: Int, _ text: String) {
        self.testNum = num
        self.testString = text
    }
}
