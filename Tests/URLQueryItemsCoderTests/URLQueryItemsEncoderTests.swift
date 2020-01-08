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
        let b = [2, 3]
        let c = C()

        struct C: Encodable {
            let ca = 4
            let cb = [5, 6]
            let cc = CC()

            struct CC: Encodable {
                let cca = 7
            }
        }
    }
    
    struct NestedContainerProperty: Encodable {
        enum Keys: CodingKey {
            case a
            case b
            case c
        }
        func encode(to encoder: Encoder) throws {
            var root = encoder.container(keyedBy: Keys.self)
            try root.encode(1, forKey: .a)
            var b = root.nestedContainer(keyedBy: Keys.self, forKey: .b)
            try b.encode(2, forKey: .a)
            try b.encode(3, forKey: .b)
            var c = root.nestedUnkeyedContainer(forKey: .c)
            try c.encode(4)
            try c.encode(5)
        }
    }
    
    func testProperty() {
        XCTAssertEqual(
            Set(try! URLQueryItemsEncoder().encode(Property())),
            Set([
                URLQueryItem(name: "a", value: "1"),
                URLQueryItem(name: "b[0]", value: "2"),
                URLQueryItem(name: "b[1]", value: "3"),
                URLQueryItem(name: "c[ca]", value: "4"),
                URLQueryItem(name: "c[cb][0]", value: "5"),
                URLQueryItem(name: "c[cb][1]", value: "6"),
                URLQueryItem(name: "c[cc][cca]", value: "7"),
            ])
        )
    }
    
    func testNestedContainerProperty() {
        XCTAssertEqual(
            Set(try URLQueryItemsEncoder().encode(NestedContainerProperty())),
            Set([
                URLQueryItem(name: "a", value: "1"),
                URLQueryItem(name: "b[a]", value: "2"),
                URLQueryItem(name: "b[b]", value: "3"),
                URLQueryItem(name: "c[0]", value: "4"),
                URLQueryItem(name: "c[1]", value: "5"),
            ])
        )
    }
    
    func testEmptyProperty() {
        XCTAssertEqual(try URLQueryItemsEncoder().encode([String: String]()), [])
    }
    
    func testUnsupported() {
        XCTAssertThrowsError(try URLQueryItemsEncoder().encode([1]))
        XCTAssertThrowsError(try URLQueryItemsEncoder().encode(1))
    }
    
    static var allTests = [
        ("testProperty", testProperty),
        ("testNestedContainerProperty", testNestedContainerProperty),
        ("testEmptyProperty", testEmptyProperty),
        ("testUnsupported", testUnsupported),
    ]
}
