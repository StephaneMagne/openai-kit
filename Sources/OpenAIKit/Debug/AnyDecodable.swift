//
//  AnyDecodable.swift
//
//  Created by Stephane Magne on 2024-01-02.
//

import Foundation

public typealias AnyDecodableDictionary = [String: AnyDecodable]

public enum AnyDecodable: Decodable {
    
    case empty
    case someValue
    indirect case array([AnyDecodable])
    indirect case dictionary([String: AnyDecodable])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dictionary = try? container.decode([String: AnyDecodable].self) {
            self = .dictionary(dictionary)
        } else if let array = try? container.decode([AnyDecodable].self) {
            self = .array(array)
        } else if container.decodeNil() {
            self = .empty
        } else {
            self = .someValue
        }
    }
}

public struct AnyDecodableHelper {
    
    public static var environmentVariable: String? {
        return ProcessInfo.processInfo.environment["OPENAI_DEBUG_RESPONSE_KEYS"]
    }
    
    public static func printKeys(for array: [AnyDecodable], indent: Int = 0) {
        for anyDecodable in array {
            switch anyDecodable {
            case .array(let array):
                printKeys(for: array, indent: indent+1)
            case .dictionary(let dictionary):
                printKeys(for: dictionary, indent: indent+1)
            case .someValue,
                 .empty:
                break
            }
        }
    }
    
    public static func printKeys(for dictionary: AnyDecodableDictionary, indent: Int = 0) {
        
        for key in dictionary.keys.sorted() {
            print("\(String(repeating: "  ", count: indent))-> \(key)")
            switch dictionary[key] {
            case .array(let array):
                printKeys(for: array)
            case .dictionary(let dictionary):
                printKeys(for: dictionary, indent: indent+1)
            case .someValue,
                 .empty,
                 .none:
                break
            }
        }
    }
}
