//
//  URLQueryItemsEncoderTests.swift
//  URLQueryItemsCoderTests
//
//  Created by Koji Murata on 2020/01/08.
//

import XCTest
@testable import URLQueryItemsCoder

class URLQueryItemsEncoderTests: XCTestCase {
    struct Property: Encodable {
        let a = 1
        let b = Date()
        let c = [1, 2]
        let d = D()

        struct D: Encodable {
            let da = 1
            let db = [1, 2]
            let dc = DC()

            struct DC: Encodable {
                let dca = 1
            }
        }
    }
    
    struct Hoge: Encodable {
        enum Keys: CodingKey {
            case a
            case b
        }
        func encode(to encoder: Encoder) throws {
            var root = encoder.container(keyedBy: Keys.self)
            try root.encode(true, forKey: .a)
            var b = root.nestedContainer(keyedBy: Keys.self, forKey: .b)
            try b.encode(1, forKey: .b)
        }
    }
    
    func testExample() {
        let queryItems = try! URLQueryItemsEncoder().encode(Property())
        print(queryItems)
//        let queryItems = try! URLQueryItemsEncoder().encode(Hoge())
//        print(queryItems)
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
}
