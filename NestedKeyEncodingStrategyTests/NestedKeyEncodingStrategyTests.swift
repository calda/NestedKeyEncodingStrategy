//
//  NestedKeyEncodingStrategyTests.swift
//  NestedKeyEncodingStrategyTests
//
//  Created by Cal Stephens on 2/22/20.
//  Copyright © 2020 Cal Stephens. All rights reserved.
//

import XCTest
import NestedKeyEncodingStrategy

// MARK: Codable objects

struct NestedObjectCoding: Codable {
    let rootValue: String
    let nestedObject: NestedObject
    
    struct NestedObject: Codable {
        let nestedValue: String
    }
    
    static let encoder = NestedKeyEncodingStrategy.JSONEncoder()
    static let decoder = NestedKeyEncodingStrategy.JSONDecoder()
}

struct NestedKeyCoding: Codable {
    let rootValue: String
    let nestedValue: String
    
    enum CodingKeys: String, CodingKey {
        case rootValue
        case nestedValue = "nestedObject.nestedValue"
    }
    
    static var encoder: NestedKeyEncodingStrategy.JSONEncoder {
        let encoder = NestedKeyEncodingStrategy.JSONEncoder()
        encoder.nestedKeyEncodingStrategy = .useDotNotation
        return encoder
    }
    
    static var decoder: NestedKeyEncodingStrategy.JSONDecoder {
        let decoder = NestedKeyEncodingStrategy.JSONDecoder()
        return decoder
    }
}

// MARK: Tests

class NestedKeyEncodingStrategyTests: XCTestCase {

    func test_encodeNested_decodeObjects() {
        let nestedKeyCodingInstance = NestedKeyCoding(
            rootValue: "root",
            nestedValue: "nested")
        
        let data = try? NestedKeyCoding.encoder.encode(nestedKeyCodingInstance)
        XCTAssertNotNil(data)
        
        XCTAssertEqual(
            data.flatMap { String(data: $0, encoding: .utf8) },
            #"{"rootValue":"root","nestedObject":{"nestedValue":"nested"}}"#)
        
        let objectCodingInstance = data.flatMap { try? NestedObjectCoding.decoder.decode(NestedObjectCoding.self, from: $0) }
        XCTAssertNotNil(objectCodingInstance)
        
        XCTAssertEqual(nestedKeyCodingInstance.rootValue, objectCodingInstance?.rootValue)
        XCTAssertEqual(nestedKeyCodingInstance.nestedValue, objectCodingInstance?.nestedObject.nestedValue)
    }
    
    func test_encodeObjects_decodeNested() {
        let objectCodingInstance = NestedObjectCoding(
            rootValue: "root",
            nestedObject: NestedObjectCoding.NestedObject(nestedValue: "nested"))
        
        let data = try? NestedObjectCoding.encoder.encode(objectCodingInstance)
        XCTAssertNotNil(data)
        
        XCTAssertEqual(
            data.flatMap { String(data: $0, encoding: .utf8) },
            #"{"rootValue":"root","nestedObject":{"nestedValue":"nested"}}"#)
        
        let nestedKeyCodingInstance = data.flatMap { try? NestedKeyCoding.decoder.decode(NestedKeyCoding.self, from: $0) }
        XCTAssertNotNil(nestedKeyCodingInstance)
        
        XCTAssertEqual(nestedKeyCodingInstance?.rootValue, objectCodingInstance.rootValue)
        XCTAssertEqual(nestedKeyCodingInstance?.nestedValue, objectCodingInstance.nestedObject.nestedValue)
    }

}
