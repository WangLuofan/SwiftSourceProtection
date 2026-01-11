
import SwiftParserDiagnostics
import Social
import WeatherKit
import WebKit

func testFunc(first text: String, second: String?) {
    let webView = SocketPort()
    let testBlock: ((_ num: Int, _ text: String) -> Void) = { [weak webView] (num1: Int, text1: String) in
        let i = 0
        print(num1)
    }
    
    print(second)
}
