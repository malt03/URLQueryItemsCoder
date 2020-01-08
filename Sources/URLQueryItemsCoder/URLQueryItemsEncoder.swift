//
//  URLQueryItemsEncoder.swift
//  URLQueryItemsCoder
//
//  Created by Koji Murata on 2020/01/08.
//

import Foundation
import Combine

open class URLQueryItemsEncoder: TopLevelEncoder {
    public func encode<T: Encodable>(_ value: T) throws -> [URLQueryItem] {
        return try NodeEncoder().encode(value).toURLQueryItems()
    }
}

public enum Node {
    case keyed([String: Node])
    case unkeyed([Node])
    case single(String)
    
    static var empty: Node { .keyed([:]) }
    
    func addingChild(key: String, _ value: Node) throws -> Node {
        switch self {
        case .keyed(var dict):
            dict[key] = value
            return .keyed(dict)
        default: throw Errors.crossContainer
        }
    }
    
    func addingChild(_ value: Node) throws -> Node {
        switch self {
        case .unkeyed(var array):
            array.append(value)
            return .unkeyed(array)
        default: throw Errors.crossContainer
        }
    }
    
    func toURLQueryItems() throws -> [URLQueryItem] {
        switch self {
        case .keyed(let dict):
            return dict.flatMap { $1.toKeyValues(parentKey: $0).map { URLQueryItem(name: $0, value: $1) } }
        default:
            throw Errors.unsupported
        }
    }
    
    private func toKeyValues(parentKey: String) -> [String: String] {
        switch self {
        case .keyed(let dict):
            return dict.reduce([String: String]()) { (result, args) -> [String: String] in
                let (i, node) = args
                return result.merging(node.toKeyValues(parentKey: "\(parentKey)[\(i)]"), uniquingKeysWith: { $1 })
            }
        case .unkeyed(let array):
            return array.enumerated().reduce([String: String]()) { (result, args) -> [String: String] in
                let (i, node) = args
                return result.merging(node.toKeyValues(parentKey: "\(parentKey)[\(i)]"), uniquingKeysWith: { $1 })
            }
        case .single(let value):
            return [parentKey: value]
        }
    }
}

fileprivate class NodeEncoder: Encoder {
    var codingPath: [CodingKey]

    var userInfo: [CodingUserInfoKey : Any] { [:] }

    private var node: Node?

    fileprivate init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(KeyedContainer(encoder: self, codingPath: codingPath))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        UnkeyedContainer(encoder: self, codingPath: codingPath)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        SingleValueContainer(encoder: self, codingPath: codingPath)
    }

    func encode<T: Encodable>(_ value: T) throws -> Node {
        try value.encode(to: self)
        return node ?? .empty
    }
    
    private class KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private(set) var codingPath: [CodingKey]

        private let encoder: NodeEncoder

        init(encoder: NodeEncoder, codingPath: [CodingKey]) {
            self.encoder = encoder
            self.codingPath = codingPath
        }

        private func setNode(_ value: Node, forKey key: Key) throws {
            if let node = encoder.node {
                encoder.node = try node.addingChild(key: key.stringValue, value)
            } else {
                encoder.node = Node.keyed([key.stringValue: value])
            }
        }
        
        private func setNode<T: CustomStringConvertible>(_ value: T, forKey key: Key) throws {
            try setNode(.single(value.description), forKey: key)
        }

        func encodeNil(forKey key: Key) throws {}

        func encode(_ value: Bool, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: String, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: Double, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: Float, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: Int, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: Int8, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: Int16, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: Int32, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: Int64, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: UInt, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: UInt8, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: UInt16, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: UInt32, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode(_ value: UInt64, forKey key: Key) throws { try setNode(value, forKey: key) }
        func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            try setNode(try NodeEncoder().encode(value), forKey: key)
        }

        func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
            codingPath.append(key)
            defer { codingPath.removeLast() }
            return KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder, codingPath: codingPath))
        }

        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            codingPath.append(key)
            defer { codingPath.removeLast() }
            return UnkeyedContainer(encoder: encoder, codingPath: codingPath)
        }

        func superEncoder() -> Encoder { encoder }
        func superEncoder(forKey key: Key) -> Encoder { encoder }
    }

    private class UnkeyedContainer: UnkeyedEncodingContainer {
        var count: Int {
            switch encoder.node ?? .empty {
            case .unkeyed(let array): return array.count
            default: return 0
            }
        }

        private(set) var codingPath: [CodingKey]

        private let encoder: NodeEncoder

        init(encoder: NodeEncoder, codingPath: [CodingKey]) {
            self.encoder = encoder
            self.codingPath = codingPath
        }

        private func setNode(_ value: Node) throws {
            if let node = encoder.node {
                encoder.node = try node.addingChild(value)
            } else {
                encoder.node = Node.unkeyed([value])
            }
        }
        
        private func setNode<T: CustomStringConvertible>(_ value: T) throws {
            try setNode(Node.single(value.description))
        }

        func encodeNil() throws {
            throw Errors.unsupported
        }
        func encode(_ value: Bool) throws { try setNode(value) }
        func encode(_ value: String) throws { try setNode(value) }
        func encode(_ value: Double) throws { try setNode(value) }
        func encode(_ value: Float) throws { try setNode(value) }
        func encode(_ value: Int) throws { try setNode(value) }
        func encode(_ value: Int8) throws { try setNode(value) }
        func encode(_ value: Int16) throws { try setNode(value) }
        func encode(_ value: Int32) throws { try setNode(value) }
        func encode(_ value: Int64) throws { try setNode(value) }
        func encode(_ value: UInt) throws { try setNode(value) }
        func encode(_ value: UInt8) throws { try setNode(value) }
        func encode(_ value: UInt16) throws { try setNode(value) }
        func encode(_ value: UInt32) throws { try setNode(value) }
        func encode(_ value: UInt64) throws { try setNode(value) }
        func encode<T: Encodable>(_ value: T) throws {
            try setNode(try NodeEncoder().encode(value))
        }

        func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
            codingPath.append(IndexCodingKey(index: count))
            defer { codingPath.removeLast() }
            return KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder, codingPath: codingPath))
        }

        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            codingPath.append(IndexCodingKey(index: count))
            defer { codingPath.removeLast() }
            return UnkeyedContainer(encoder: encoder, codingPath: codingPath)
        }

        func superEncoder() -> Encoder { encoder }
        
        struct IndexCodingKey: CodingKey {
            init?(stringValue: String) { nil }
            let stringValue = ""
            
            var intValue: Int?
            init?(intValue: Int) { self.intValue = intValue }
            init(index: Int) { intValue = index }
        }
    }

    private class SingleValueContainer: SingleValueEncodingContainer {
        private(set) var codingPath: [CodingKey]

        private let encoder: NodeEncoder

        init(encoder: NodeEncoder, codingPath: [CodingKey]) {
            self.encoder = encoder
            self.codingPath = codingPath
        }
        
        private func setNode(_ value: Node) throws {
            switch encoder.node {
            case .single, nil:
                encoder.node = value
            default: throw Errors.crossContainer
            }
        }

        private func setNode<T: CustomStringConvertible>(_ value: T) throws {
            try setNode(.single(value.description))
        }

        func encodeNil() throws {}
        func encode(_ value: Bool) throws { try setNode(value) }
        func encode(_ value: String) throws { try setNode(value) }
        func encode(_ value: Double) throws { try setNode(value) }
        func encode(_ value: Float) throws { try setNode(value) }
        func encode(_ value: Int) throws { try setNode(value) }
        func encode(_ value: Int8) throws { try setNode(value) }
        func encode(_ value: Int16) throws { try setNode(value) }
        func encode(_ value: Int32) throws { try setNode(value) }
        func encode(_ value: Int64) throws { try setNode(value) }
        func encode(_ value: UInt) throws { try setNode(value) }
        func encode(_ value: UInt8) throws { try setNode(value) }
        func encode(_ value: UInt16) throws { try setNode(value) }
        func encode(_ value: UInt32) throws { try setNode(value) }
        func encode(_ value: UInt64) throws { try setNode(value) }
        func encode<T: Encodable>(_ value: T) throws {
            try setNode(try NodeEncoder().encode(value))
        }
    }
}

