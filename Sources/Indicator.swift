//
//  Indicator.swift
//  Kingfisher
//
//  Created by João D. Moreira on 30/08/16.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
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

#if os(OSX)
    import AppKit
#else
    import UIKit
#endif

#if os(OSX)
    public typealias IndicatorView = NSView
#else
    public typealias IndicatorView = UIView
#endif

// MARK: - Indicator Protocol
public protocol Indicator {
    func startAnimatingView()
    func stopAnimatingView()

    var viewCenter: CGPoint { get set }
    var view: IndicatorView { get }
}

extension Indicator {
    #if os(OSX)
    var viewCenter: CGPoint {
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
    var viewCenter: CGPoint {
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
struct ActivityIndicator: Indicator {

    #if os(OSX)
    private let activityIndicatorView: NSProgressIndicator
    #else
    private let activityIndicatorView: UIActivityIndicatorView
    #endif

    var view: IndicatorView {
        return activityIndicatorView
    }

    func startAnimatingView() {
        #if os(OSX)
            activityIndicatorView.startAnimation(nil)
        #else
            activityIndicatorView.startAnimating()
        #endif
        activityIndicatorView.hidden = false
    }

    func stopAnimatingView() {
        #if os(OSX)
            activityIndicatorView.stopAnimation(nil)
        #else
            activityIndicatorView.stopAnimating()
        #endif
        activityIndicatorView.hidden = true
    }

    init() {
        #if os(OSX)
            activityIndicatorView = NSProgressIndicator(frame: CGRect(x: 0, y: 0, width: 16, height: 16))

            #if swift(>=2.3)
                activityIndicatorView.controlSize = .Small
            #else
                activityIndicatorView.controlSize = .SmallControlSize
            #endif
            activityIndicatorView.style = .SpinningStyle
        #else
            #if os(tvOS)
                let indicatorStyle = UIActivityIndicatorViewStyle.White
            #else
                let indicatorStyle = UIActivityIndicatorViewStyle.Gray
            #endif
            activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle:indicatorStyle)
            activityIndicatorView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleTopMargin]
        #endif
    }
}

// MARK: - ImageIndicator
// Displays an ImageView. Supports gif
struct ImageIndicator: Indicator {
    private let animatedImageIndicatorView: ImageView

    var view: IndicatorView {
        return animatedImageIndicatorView
    }

    init(imageData data: NSData) {

        let image = Image.kf_imageWithData(data, scale: 1.0, preloadAllGIFData: true)
        animatedImageIndicatorView = ImageView()
        animatedImageIndicatorView.image = image
        
        #if os(OSX)
            // Need for gif to animate on OSX
            self.animatedImageIndicatorView.imageScaling = .ScaleNone
            self.animatedImageIndicatorView.canDrawSubviewsIntoLayer = true
        #else
            animatedImageIndicatorView.contentMode = .Center
            
            animatedImageIndicatorView.autoresizingMask = [.FlexibleLeftMargin,
                                                           .FlexibleRightMargin,
                                                           .FlexibleBottomMargin,
                                                           .FlexibleTopMargin]
        #endif
    }

    func startAnimatingView() {
        #if os(OSX)
            animatedImageIndicatorView.animates = true
        #else
            animatedImageIndicatorView.startAnimating()
        #endif
        animatedImageIndicatorView.hidden = false
    }

    func stopAnimatingView() {
        #if os(OSX)
            animatedImageIndicatorView.animates = false
        #else
            animatedImageIndicatorView.stopAnimating()
        #endif
        animatedImageIndicatorView.hidden = true
    }
}
