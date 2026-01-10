func testFunc(first text: String, second: String?) {
    let r: Int? = 0
    let q: String? = "123"
   
    guard let rp: Int = r else {
        return
    }
    
    print(second)
}
