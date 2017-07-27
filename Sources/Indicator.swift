//
//  Indicator.swift
//  Kingfisher
//
//  Created by João D. Moreira on 30/08/16.
//
//  Copyright (c) 2017 Wei Wang <onevcat@gmail.com>
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

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

#if os(macOS)
    public typealias IndicatorView = NSView
#else
    public typealias IndicatorView = UIView
#endif

public enum IndicatorType {
    /// No indicator.
    case none
    /// Use system activity indicator.
    case activity
    /// Use an image as indicator. GIF is supported.
    case image(imageData: Data)
    /// Use a custom indicator, which conforms to the `Indicator` protocol.
    case custom(indicator: Indicator)
}

// MARK: - Indicator Protocol
public protocol Indicator {
    func startAnimatingView()
    func stopAnimatingView()

    var viewCenter: CGPoint { get set }
    var view: IndicatorView { get }
}

extension Indicator {
    #if os(macOS)
    public var viewCenter: CGPoint {
        get {
            let frame = view.frame
            return CGPoint(x: frame.origin.x + frame.size.width / 2.0, y: frame.origin.y + frame.size.height / 2.0 )
        }
        set {
            let frame = view.frame
            let newFrame = CGRect(x: newValue.x - frame.size.width / 2.0,
                                  y: newValue.y - frame.size.height / 2.0,
                                  width: frame.size.width,
                                  height: frame.size.height)
            view.frame = newFrame
        }
    }
    #else
    public var viewCenter: CGPoint {
        get {
            return view.center
        }
        set {
            view.center = newValue
        }
    }
    #endif
}

// MARK: - ActivityIndicator
// Displays a NSProgressIndicator / UIActivityIndicatorView
class ActivityIndicator: Indicator {

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
        animatingCount += 1
        // Alrady animating
        if animatingCount == 1 {
            #if os(macOS)
                activityIndicatorView.startAnimation(nil)
            #else
                activityIndicatorView.startAnimating()
            #endif
            activityIndicatorView.isHidden = false
        }
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

    init() {
        #if os(macOS)
            activityIndicatorView = NSProgressIndicator(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
            activityIndicatorView.controlSize = .small
            activityIndicatorView.style = .spinning
        #else
            #if os(tvOS)
                let indicatorStyle = UIActivityIndicatorViewStyle.white
            #else
                let indicatorStyle = UIActivityIndicatorViewStyle.gray
            #endif
            activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle:indicatorStyle)
            activityIndicatorView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleTopMargin]
        #endif
    }
}

// MARK: - ImageIndicator
// Displays an ImageView. Supports gif
class ImageIndicator: Indicator {
    private let animatedImageIndicatorView: ImageView

    var view: IndicatorView {
        return animatedImageIndicatorView
    }

    init?(imageData data: Data, processor: ImageProcessor = DefaultImageProcessor.default, options: KingfisherOptionsInfo = KingfisherEmptyOptionsInfo) {

        var options = options
        // Use normal image view to show animations, so we need to preload all animation data.
        if !options.preloadAllAnimationData {
            options.append(.preloadAllAnimationData)
        }
        
        guard let image = processor.process(item: .data(data), options: options) else {
            return nil
        }

        animatedImageIndicatorView = ImageView()
        animatedImageIndicatorView.image = image
        animatedImageIndicatorView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        
        #if os(macOS)
            // Need for gif to animate on macOS
            self.animatedImageIndicatorView.imageScaling = .scaleNone
            self.animatedImageIndicatorView.canDrawSubviewsIntoLayer = true
        #else
            animatedImageIndicatorView.contentMode = .center
            animatedImageIndicatorView.autoresizingMask = [.flexibleLeftMargin,
                                                           .flexibleRightMargin,
                                                           .flexibleBottomMargin,
                                                           .flexibleTopMargin]
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
