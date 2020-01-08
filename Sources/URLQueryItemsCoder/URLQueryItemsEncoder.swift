//
//  URLQueryItemsEncoder.swift
//  URLQueryItemsCoder
//
//  Created by Koji Murata on 2020/01/08.
//

import Foundation

open class URLQueryItemsEncoder {
    public func encode<T: Encodable>(_ value: T) throws -> [URLQueryItem] {
        return try NodeEncoder().encode(value).toURLQueryItems()
    }
}

public final class Node {
    var dict: [String: Node]?
    var array: [Node]?
    var value: String?
    
    static var empty: Node { Node(dict: nil, array: nil, value: nil, kind: .empty) }
    static func single(_ value: String) -> Node { Node(dict: nil, array: nil, value: value, kind: .single) }
    
    init(dict: [String: Node]?, array: [Node]?, value: String?, kind: Kind) {
        self.dict = dict
        self.array = array
        self.value = value
        self.kind = kind
    }
    
    private var kind = Kind.empty
    
    enum Kind {
        case keyed
        case unkeyed
        case single
        case empty
    }
    
    func addChild(node: Node, forKey key: String) throws {
        switch kind {
        case .empty:
            kind = .keyed
            dict = [key: node]
        case .keyed:
            dict![key] = node
        default:
            throw Errors.crossContainer
        }
    }
    
    func addChild(node: Node) throws {
        switch kind {
        case .empty:
            kind = .unkeyed
            array = [node]
        case .unkeyed:
            array!.append(node)
        default:
            throw Errors.crossContainer
        }
    }
    
    func setValue(_ value: String) throws {
        switch kind {
        case .empty:
            kind = .single
            self.value = value
        case .single:
            self.value = value
        default:
            throw Errors.crossContainer
        }
    }
    
    func forceCopy(_ target: Node) {
        self.dict = target.dict
        self.array = target.array
        self.value = target.value
        self.kind = target.kind
    }
    
    func toURLQueryItems() throws -> [URLQueryItem] {
        switch kind {
        case .keyed:
            return dict!.flatMap { $1.toKeyValues(parentKey: $0).map { URLQueryItem(name: $0, value: $1) } }
        case .empty:
            return []
        default:
            throw Errors.unsupported
        }
    }
    
    private func toKeyValues(parentKey: String) -> [String: String] {
        switch kind {
        case .keyed:
            return dict!.reduce([String: String]()) { (result, args) -> [String: String] in
                let (i, node) = args
                return result.merging(node.toKeyValues(parentKey: "\(parentKey)[\(i)]"), uniquingKeysWith: { $1 })
            }
        case .unkeyed:
            return array!.enumerated().reduce([String: String]()) { (result, args) -> [String: String] in
                let (i, node) = args
                return result.merging(node.toKeyValues(parentKey: "\(parentKey)[\(i)]"), uniquingKeysWith: { $1 })
            }
        case .single:
            return [parentKey: value!]
        case .empty:
            return [:]
        }
    }
}

fileprivate class NodeEncoder: Encoder {
    var codingPath: [CodingKey]

    var userInfo: [CodingUserInfoKey : Any] { [:] }

    private var node = Node.empty

    fileprivate init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(KeyedContainer(targetNode: node, encoder: self, codingPath: codingPath))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        UnkeyedContainer(targetNode: node, encoder: self, codingPath: codingPath)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        SingleValueContainer(targetNode: node, encoder: self, codingPath: codingPath)
    }

    func encode<T: Encodable>(_ value: T) throws -> Node {
        try value.encode(to: self)
        return node
    }
    
    private class KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        private(set) var codingPath: [CodingKey]

        private let encoder: NodeEncoder
        private let targetNode: Node

        init(targetNode: Node, encoder: NodeEncoder, codingPath: [CodingKey]) {
            self.targetNode = targetNode
            self.encoder = encoder
            self.codingPath = codingPath
        }
        
        private func setNode(_ node: Node, forKey key: Key) throws {
            try targetNode.addChild(node: node, forKey: key.stringValue)
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
            let nestedNode = Node.empty
            try! setNode(nestedNode, forKey: key)
            return KeyedEncodingContainer(KeyedContainer<NestedKey>(targetNode: nestedNode, encoder: encoder, codingPath: codingPath))
        }

        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            let nestedNode = Node.empty
            try! setNode(nestedNode, forKey: key)
            return UnkeyedContainer(targetNode: nestedNode, encoder: encoder, codingPath: codingPath)
        }

        func superEncoder() -> Encoder { encoder }
        func superEncoder(forKey key: Key) -> Encoder { encoder }
    }

    private class UnkeyedContainer: UnkeyedEncodingContainer {
        var count: Int { encoder.node.array?.count ?? 0 }

        private(set) var codingPath: [CodingKey]

        private let encoder: NodeEncoder
        private let targetNode: Node

        init(targetNode: Node, encoder: NodeEncoder, codingPath: [CodingKey]) {
            self.targetNode = targetNode
            self.encoder = encoder
            self.codingPath = codingPath
        }

        private func setNode(_ node: Node) throws {
            try targetNode.addChild(node: node)
        }
        
        private func setNode<T: CustomStringConvertible>(_ value: T) throws {
            try setNode(.single(value.description))
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
            let nestedNode = Node.empty
            try! setNode(nestedNode)
            return KeyedEncodingContainer(KeyedContainer<NestedKey>(targetNode: nestedNode, encoder: encoder, codingPath: codingPath))
        }

        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            let nestedNode = Node.empty
            try! setNode(nestedNode)
            return UnkeyedContainer(targetNode: nestedNode, encoder: encoder, codingPath: codingPath)
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
        private let targetNode: Node
        
        init(targetNode: Node, encoder: NodeEncoder, codingPath: [CodingKey]) {
            self.targetNode = targetNode
            self.encoder = encoder
            self.codingPath = codingPath
        }
        
        private func setNode<T: CustomStringConvertible>(_ value: T) throws {
            try targetNode.setValue(value.description)
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
            targetNode.forceCopy(try NodeEncoder().encode(value))
        }
    }
}

