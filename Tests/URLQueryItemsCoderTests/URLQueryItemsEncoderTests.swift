//
//  URLQueryItemsEncoderTests.swift
//  URLQueryItemsCoderTests
//
//  Created by Koji Murata on 2020/01/08.
//

import XCTest
@testable import URLQueryItemsCoder

class URLQueryItemsEncoderTests: XCTestCase {
    let node = Node.keyed(
        [
            "a": Node.single("v-a"),
            "b": Node.keyed([
                "b_a": Node.single("v-b_a"),
                "b_b": Node.keyed([
                    "b_b_a": Node.single("v-b_b_a"),
                ]),
                "b_c": Node.unkeyed([
                    Node.single("v-b_c_0")
                ]),
            ]),
            "c": Node.unkeyed([
                Node.single("v-c_0"),
                Node.keyed([
                    "c_1_a": Node.single("v-c_1_a"),
                ]),
                Node.unkeyed([
                    Node.single("v-c_2_0"),
                ]),
            ])
        ]
    )
    
//    let result = [
//        "a": "v-a",
//        "b[b_a]": "v-b_a",
//        "b[b_b][b_b_a]": "v-b_b_a",
//        "b[b_c][0]": "v-b_c_0",
//        "c[0]": "v-c_0",
//        "c[1][c_1_a]": "v-c_1_a",
//        "c[2][0]": "v-c_2_0",
//    ]
    
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
//        let queryItems = try! URLQueryItemsEncoder().encode(Property())
//        print(queryItems)
        let queryItems = try! URLQueryItemsEncoder().encode(Hoge())
        print(queryItems)
    }
    
    static var allTests = [
        ("testExample", testExample),
    ]
}
