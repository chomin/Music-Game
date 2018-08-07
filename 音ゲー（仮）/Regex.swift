//
//  Regex.swift
//  ha1fRegex
//
//  Created by はるふ on 2016/09/30.
//  Copyright © 2016年 はるふ. All rights reserved.
//

import Foundation

public struct Regex {
    public struct Match {
        public let wholeString: String
        public let groups: [String?]
        
        init(text: NSString, result res: NSTextCheckingResult) {
            let components = (0..<res.numberOfRanges)
                .map { i -> String? in
                    let range = res.range(at: i)
                    guard range.location != NSNotFound else {
                        // ない可能性のある()だとnilのこともある
                        return nil
                    }
                    return text.substring(with: res.range(at: i))
            }
            self.wholeString = components.first.flatMap { $0 } ?? ""
            self.groups = components.dropFirst().map { $0 }
        }
    }
    
    // MARK: Properties
    
    fileprivate let regex: NSRegularExpression
    
    // MARK: Initializers
    
    public init(_ pattern: String, options: NSRegularExpression.Options = []) throws {
        do {
            self.regex = try NSRegularExpression(pattern: pattern, options: options)
        }
    }
    
    // MARK: Public functions
    
    public func matches(_ string: String, range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> Bool {
        return self.firstMatch(string, range: range, options: options) != nil
    }
    
    public func firstMatch(_ string: String, range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> Match? {
        let targetRange = range ?? string.wholeNSRange()
        let nsstring = string as NSString
        if let res = self.regex.firstMatch(in: string, options: options, range: targetRange) {
            return Regex.Match(text: nsstring, result: res)
        } else {
            return nil
        }
    }
    
    public func allMatches(_ string: String, range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> [Match] {
        let targetRange = range ?? string.wholeNSRange()
        let nsstring = string as NSString
        return self.regex.matches(in: string, options: options, range: targetRange).map { res in
            return Regex.Match(text: nsstring, result: res)
        }
    }
}

extension Regex {
    // MARK: Preset regexes
    
    private static let PATTERN_FLOAT = "-*([1-9]\\d*|0)(\\.\\d+)?"
    private static let PATTERN_EMAIL = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)+$"
    
    public static let email = try! Regex(PATTERN_EMAIL)
    public static let float = try! Regex(PATTERN_FLOAT)
}

extension String {
    // MARK: Extensions of String
    
    fileprivate func wholeRange() -> Range<String.Index> {
        return self.startIndex..<self.endIndex
    }
    
    fileprivate func wholeNSRange() -> NSRange {
        return NSRange(location: 0, length: self.count)
    }
    
    public func replace(_ regex: Regex, with template: String, range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> String {
        let targetRange = range ?? self.wholeNSRange()
        return regex.regex.stringByReplacingMatches(in: self, options: options, range: targetRange, withTemplate: template)
    }
    
    /// (を(?:で置換する
    public func ignoringExtractions() -> String {
        return replace(try! Regex("\\((?!\\?:)"), with: "(?:")
    }
}
