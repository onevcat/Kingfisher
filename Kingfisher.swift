//
//  Kingfisher.swift
//  Kingfisher
//
//  Created by WANG WEI on 2016/09/14.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

import Foundation

#if os(macOS)
    import AppKit
    public typealias Image = NSImage
    public typealias Color = NSColor
    public typealias ImageView = NSImageView
    typealias Button = NSButton
#else
    import UIKit
    public typealias Image = UIImage
    public typealias Color = UIColor
    public typealias ImageView = UIImageView
    typealias Button = UIButton
#endif

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
extension Button: KingfisherCompatible { }
