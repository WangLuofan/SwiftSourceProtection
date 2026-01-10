
import SwiftParserDiagnostics
import Social
import WeatherKit
import WebKit

func testFunc(first text: String, second: String?) {
    let r: Int? = 0
    let q: String? = "123"
   
    guard let rp: Int = r else {
        return
    }
    
    do {
        var count: Int = 0
        while let rq = r, rq > 0 {
            let s = 1
            count += s
        }
    }
    
    print(second)
}
