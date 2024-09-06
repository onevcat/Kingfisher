//
//  Indicator.swift
//  Kingfisher
//
//  Created by João D. Moreira on 30/08/16.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if !os(watchOS)

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
public typealias IndicatorView = NSView
#else
import UIKit
public typealias IndicatorView = UIView
#endif

/// Represents the activity indicator type that should be added to an image view when an image is being downloaded.
public enum IndicatorType {
    
    /// No indicator.
    case none
    
    /// Uses the system activity indicator.
    case activity
    
    /// Uses an image as an indicator. GIF is supported.
    case image(imageData: Data)
    
    /// Uses a custom indicator.
    ///
    /// The type of the associated value should conform to the ``Indicator`` protocol.
    case custom(indicator: any Indicator)
}

/// An indicator type which can be used to show that the download task is in progress.
@MainActor 
public protocol Indicator: Sendable {
    
    /// Called when the indicator should start animating.
    func startAnimatingView()
    
    /// Called when the indicator should stop animating.
    func stopAnimatingView()

    /// Center offset of the indicator.
    ///
    /// Kingfisher will use this value to determine the position of the indicator in the superview.
    var centerOffset: CGPoint { get }
    
    /// The indicator view which would be added to the superview.
    var view: IndicatorView { get }

    /// The size strategy used when adding the indicator to the image view.
    /// - Parameter imageView: The superview of the indicator.
    /// - Returns: An ``IndicatorSizeStrategy`` that determines how the indicator should be sized.
    func sizeStrategy(in imageView: KFCrossPlatformImageView) -> IndicatorSizeStrategy
}

/// The idicator size strategy used when sizing the indicator in the image view.
public enum IndicatorSizeStrategy {
    /// Uses the intrinsic size of the indicator.
    case intrinsicSize
    /// Match the size of the super view of the indicator.
    case full
    /// Uses the associated `CGSize` to set the indicator size.
    case size(CGSize)
}

extension Indicator {
    
    /// Default implementation of ``Indicator/centerOffset-7jxdw`` of the ``Indicator``.
    ///
    /// The default value is `.zero`, which means that there is no offset for the indicator view.
    public var centerOffset: CGPoint {
        .zero
    }

    /// Default implementation of ``Indicator/sizeStrategy(in:)-5x0b4`` of the ``Indicator``.
    ///
    /// The default value is ``IndicatorSizeStrategy/full``, means that the indicator will pin to the same height and
    /// width as the image view.
    /// - Parameter imageView: The image view which holds the indicator.
    /// - Returns: The desired ``IndicatorSizeStrategy``
    public func sizeStrategy(in imageView: KFCrossPlatformImageView) -> IndicatorSizeStrategy {
        .full
    }
}

// Displays a NSProgressIndicator / UIActivityIndicatorView
@MainActor
final class ActivityIndicator: Indicator {

    #if os(macOS)
    private let activityIndicatorView: NSProgressIndicator
    #else
    private let activityIndicatorView: UIActivityIndicatorView
    #endif
    private var animatingCount = 0

    var view: IndicatorView {
        return activityIndicatorView
    }

    func startAnimatingView() {
        if animatingCount == 0 {
            #if os(macOS)
            activityIndicatorView.startAnimation(nil)
            #else
            activityIndicatorView.startAnimating()
            #endif
            activityIndicatorView.isHidden = false
        }
        animatingCount += 1
    }

    func stopAnimatingView() {
        animatingCount = max(animatingCount - 1, 0)
        if animatingCount == 0 {
            #if os(macOS)
                activityIndicatorView.stopAnimation(nil)
            #else
                activityIndicatorView.stopAnimating()
            #endif
            activityIndicatorView.isHidden = true
        }
    }

    func sizeStrategy(in imageView: KFCrossPlatformImageView) -> IndicatorSizeStrategy {
        return .intrinsicSize
    }

    init() {
        #if os(macOS)
            activityIndicatorView = NSProgressIndicator(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
            activityIndicatorView.controlSize = .small
            activityIndicatorView.style = .spinning
        #else
            let indicatorStyle: UIActivityIndicatorView.Style

            #if os(tvOS)
            if #available(tvOS 13.0, *) {
                indicatorStyle = UIActivityIndicatorView.Style.large
            } else {
                indicatorStyle = UIActivityIndicatorView.Style.white
            }
            #elseif os(visionOS)
            indicatorStyle = UIActivityIndicatorView.Style.medium
            #else
            if #available(iOS 13.0, * ) {
                indicatorStyle = UIActivityIndicatorView.Style.medium
            } else {
                indicatorStyle = UIActivityIndicatorView.Style.gray
            }
            #endif

            activityIndicatorView = UIActivityIndicatorView(style: indicatorStyle)
        #endif
    }
}

#if canImport(UIKit)
extension UIActivityIndicatorView.Style {
    #if compiler(>=5.1)
    #else
    static let large = UIActivityIndicatorView.Style.white
    #if !os(tvOS)
    static let medium = UIActivityIndicatorView.Style.gray
    #endif
    #endif
}
#endif

// MARK: - ImageIndicator
// Displays an ImageView. Supports gif
final class ImageIndicator: Indicator {
    private let animatedImageIndicatorView: KFCrossPlatformImageView

    var view: IndicatorView {
        return animatedImageIndicatorView
    }

    init?(
        imageData data: Data,
        processor: any ImageProcessor = DefaultImageProcessor.default,
        options: KingfisherParsedOptionsInfo? = nil)
    {
        var options = options ?? KingfisherParsedOptionsInfo(nil)
        // Use normal image view to show animations, so we need to preload all animation data.
        if !options.preloadAllAnimationData {
            options.preloadAllAnimationData = true
        }
        
        guard let image = processor.process(item: .data(data), options: options) else {
            return nil
        }

        animatedImageIndicatorView = KFCrossPlatformImageView()
        animatedImageIndicatorView.image = image
        
        #if os(macOS)
            // Need for gif to animate on macOS
            animatedImageIndicatorView.imageScaling = .scaleNone
            animatedImageIndicatorView.canDrawSubviewsIntoLayer = true
        #else
            animatedImageIndicatorView.contentMode = .center
        #endif
    }

    func startAnimatingView() {
        #if os(macOS)
            animatedImageIndicatorView.animates = true
        #else
            animatedImageIndicatorView.startAnimating()
        #endif
        animatedImageIndicatorView.isHidden = false
    }

    func stopAnimatingView() {
        #if os(macOS)
            animatedImageIndicatorView.animates = false
        #else
            animatedImageIndicatorView.stopAnimating()
        #endif
        animatedImageIndicatorView.isHidden = true
    }
}

#endif
