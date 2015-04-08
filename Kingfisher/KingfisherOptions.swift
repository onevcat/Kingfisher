//
//  KingfisherOptions.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
//  Copyright (c) 2015年 Wei Wang. All rights reserved.
//

import Foundation

public struct KingfisherOptions : RawOptionSetType {
    typealias RawValue = UInt
    private var value: UInt = 0
    init(_ value: UInt) { self.value = value }
    public init(rawValue value: UInt) { self.value = value }
    public init(nilLiteral: ()) { self.value = 0 }
    public static var allZeros: KingfisherOptions { return self(0) }
    static func fromMask(raw: UInt) -> KingfisherOptions { return self(raw) }
    public var rawValue: UInt { return self.value }
    
    public static var None: KingfisherOptions { return self(0) }
    public static var LowPriority: KingfisherOptions { return KingfisherOptions(1 << 0) }
    public static var ForceRefresh: KingfisherOptions { return KingfisherOptions(1 << 1) }
    public static var CacheMemoryOnly: KingfisherOptions { return KingfisherOptions(1 << 2) }
    public static var BackgroundDecode: KingfisherOptions { return KingfisherOptions(1 << 3) }
}
