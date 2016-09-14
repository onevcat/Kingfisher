//
//  Kingfisher.swift
//  Kingfisher
//
//  Created by WANG WEI on 2016/09/14.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

import Foundation

public struct Kingfisher<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

/**
 A type that has Kingfisher extensions.
 */
public protocol KingfisherCompatible {
    associatedtype CompatibleType
    var kf: Kingfisher<CompatibleType> { get set }
}

public extension KingfisherCompatible {
    public var kf: Kingfisher<Self> {
        get { return Kingfisher(self) }
        set { }
    }
}

extension ImageView: KingfisherCompatible { }
extension Image: KingfisherCompatible { }
