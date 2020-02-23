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
        decoder.nestedKeyDecodingStrategy = .useDotNotation
        return decoder
    }
}

// MARK: Tests

class NestedKeyEncodingStrategyTests: XCTestCase {

    func test_encodeNestedKeys_decodeObjects() throws {
        let nestedKeyCodingInstance = NestedKeyCoding(
            rootValue: "root",
            nestedValue: "nested")
        
        let data = try NestedKeyCoding.encoder.encode(nestedKeyCodingInstance)
        XCTAssertNotNil(data)
        
        XCTAssertEqual(
            String(data: data, encoding: .utf8),
            #"{"rootValue":"root","nestedObject":{"nestedValue":"nested"}}"#)
        
        let objectCodingInstance = try NestedObjectCoding.decoder.decode(NestedObjectCoding.self, from: data)
        XCTAssertNotNil(objectCodingInstance)
        
        XCTAssertEqual(nestedKeyCodingInstance.rootValue, objectCodingInstance.rootValue)
        XCTAssertEqual(nestedKeyCodingInstance.nestedValue, objectCodingInstance.nestedObject.nestedValue)
    }
    
    func test_encodeObjects_decodeNestedKeys() throws {
        let objectCodingInstance = NestedObjectCoding(
            rootValue: "root",
            nestedObject: NestedObjectCoding.NestedObject(nestedValue: "nested"))
        
        let data = try NestedObjectCoding.encoder.encode(objectCodingInstance)
        XCTAssertNotNil(data)
        
        XCTAssertEqual(
            String(data: data, encoding: .utf8),
            #"{"rootValue":"root","nestedObject":{"nestedValue":"nested"}}"#)
        
        let nestedKeyCodingInstance = try NestedKeyCoding.decoder.decode(NestedKeyCoding.self, from: data)
        XCTAssertNotNil(nestedKeyCodingInstance)
        
        XCTAssertEqual(nestedKeyCodingInstance.rootValue, objectCodingInstance.rootValue)
        XCTAssertEqual(nestedKeyCodingInstance.nestedValue, objectCodingInstance.nestedObject.nestedValue)
    }
    
    func test_decodeNested_failsBecauseOfTypeMismatch() throws {
        let jsonData = Data(#"{"rootValue":"root","nestedObject":"value"}"#.utf8)
        
        XCTAssertThrowsError(
            try NestedKeyCoding.decoder.decode(NestedKeyCoding.self, from: jsonData))
            { AssertIsDecodingTypeMismatchError($0, at: "nestedObject") }
    }
    
    func test_decodeNested_failsBecauseOfMissingKeyAtStartOfPath() throws {
        let jsonData = Data(#"{"rootValue":"root","nestedDictionary":{"nestedValue":"nested"}}"#.utf8)
        
        XCTAssertThrowsError(
            try NestedKeyCoding.decoder.decode(NestedKeyCoding.self, from: jsonData))
            { AssertIsDecodingKeyNotFoundError($0, at: "") }
    }
    
    func test_decodeNested_failsBecauseOfMissingKeyAtEndOfPath() throws {
        let jsonData = Data(#"{"rootValue":"root","nestedObject":{"nestedString":"nested"}}"#.utf8)
        
        XCTAssertThrowsError(
            try NestedKeyCoding.decoder.decode(NestedKeyCoding.self, from: jsonData))
            { AssertIsDecodingKeyNotFoundError($0, at: "nestedObject") }
    }

}

// MARK: Error Handling helpers

func AssertIsDecodingTypeMismatchError(
    _ error: Error,
    at expectedPath: String,
    file: StaticString = #file,
    line: UInt = #line)
{
    switch error as? DecodingError {
    case .typeMismatch(_, let context):
        let errorPath = context.codingPath.map { $0.stringValue }.joined(separator: ".")
        XCTAssertEqual(errorPath, expectedPath, "Unexpected coding path: \(errorPath)", file: file, line: line)
    default:
        XCTAssertTrue(false, "Expected `DecodingError.typeMismatch`, got \(error)", file: file, line: line)
    }
}

func AssertIsDecodingKeyNotFoundError(
    _ error: Error,
    at expectedPath: String,
    file: StaticString = #file,
    line: UInt = #line)
{
    switch error as? DecodingError {
    case .keyNotFound(_, let context):
        let errorPath = context.codingPath.map { $0.stringValue }.joined(separator: ".")
        XCTAssertEqual(errorPath, expectedPath, "Unexpected coding path: \(errorPath)", file: file, line: line)
    default:
        XCTAssertTrue(false, "Expected `DecodingError.typeMismatch`, got \(error)", file: file, line: line)
    }
}
