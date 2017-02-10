//
//  AnimatableImageView.swift
//  Kingfisher
//
//  Created by bl4ckra1sond3tre on 4/22/16.
//
//  The AnimatableImageView, AnimatedFrame and Animator is a modified version of 
//  some classes from kaishin's Gifu project (https://github.com/kaishin/Gifu)
//
//  The MIT License (MIT)
//
//  Copyright (c) 2017 Reda Lemeden.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  The name and characters used in the demo of this software are property of their
//  respective owners.

import UIKit
import ImageIO

/// `AnimatedImageView` is a subclass of `UIImageView` for displaying animated image.
open class AnimatedImageView: UIImageView {
    
    /// Proxy object for prevending a reference cycle between the CADDisplayLink and AnimatedImageView.
    class TargetProxy {
        private weak var target: AnimatedImageView?
        
        init(target: AnimatedImageView) {
            self.target = target
        }
        
        @objc func onScreenUpdate() {
            target?.updateFrame()
        }
    }
    
    // MARK: - Public property
    /// Whether automatically play the animation when the view become visible. Default is true.
    public var autoPlayAnimatedImage = true
    
    /// The size of the frame cache.
    public var framePreloadCount = 10
    
    /// Specifies whether the GIF frames should be pre-scaled to save memory. Default is true.
    public var needsPrescaling = true
    
    /// The animation timer's run loop mode. Default is `NSRunLoopCommonModes`. Set this property to `NSDefaultRunLoopMode` will make the animation pause during UIScrollView scrolling.
    public var runLoopMode = RunLoopMode.commonModes {
        willSet {
            if runLoopMode == newValue {
                return
            } else {
                stopAnimating()
                displayLink.remove(from: .main, forMode: runLoopMode)
                displayLink.add(to: .main, forMode: newValue)
                startAnimating()
            }
        }
    }
    
    // MARK: - Private property
    /// `Animator` instance that holds the frames of a specific image in memory.
    private var animator: Animator?
    
    /// A flag to avoid invalidating the displayLink on deinit if it was never created, because displayLink is so lazy. :D
    private var isDisplayLinkInitialized: Bool = false
    
    /// A display link that keeps calling the `updateFrame` method on every screen refresh.
    private lazy var displayLink: CADisplayLink = {
        self.isDisplayLinkInitialized = true
        let displayLink = CADisplayLink(target: TargetProxy(target: self), selector: #selector(TargetProxy.onScreenUpdate))
        displayLink.add(to: .main, forMode: self.runLoopMode)
        displayLink.isPaused = true
        return displayLink
    }()
    
    // MARK: - Override
    override open var image: Image? {
        didSet {
            if image != oldValue {
                reset()
            }
            setNeedsDisplay()
            layer.setNeedsDisplay()
        }
    }
    
    deinit {
        if isDisplayLinkInitialized {
            displayLink.invalidate()
        }
    }
    
    override open var isAnimating: Bool {
        if isDisplayLinkInitialized {
            return !displayLink.isPaused
        } else {
            return super.isAnimating
        }
    }
    
    /// Starts the animation.
    override open func startAnimating() {
        if self.isAnimating {
            return
        } else {
            displayLink.isPaused = false
        }
    }
    
    /// Stops the animation.
    override open func stopAnimating() {
        super.stopAnimating()
        if isDisplayLinkInitialized {
            displayLink.isPaused = true
        }
    }
    
    override open func display(_ layer: CALayer) {
        if let currentFrame = animator?.currentFrame {
            layer.contents = currentFrame.cgImage
        } else {
            layer.contents = image?.cgImage
        }
    }
    
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        didMove()
    }
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        didMove()
    }
    
    // This is for back compatibility that using regular UIImageView to show GIF.
    override func shouldPreloadAllGIF() -> Bool {
        return false
    }
    
    // MARK: - Private method
    /// Reset the animator.
    private func reset() {
        animator = nil
        if let imageSource = image?.kf.imageSource?.imageRef {
            animator = Animator(imageSource: imageSource, contentMode: contentMode, size: bounds.size, framePreloadCount: framePreloadCount)
            animator?.needsPrescaling = needsPrescaling
            animator?.prepareFramesAsynchronously()
        }
        didMove()
    }
    
    private func didMove() {
        if autoPlayAnimatedImage && animator != nil {
            if let _ = superview, let _ = window {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }
    
    /// Update the current frame with the displayLink duration.
    private func updateFrame() {
        if animator?.updateCurrentFrame(duration: displayLink.duration) ?? false {
            layer.setNeedsDisplay()
        }
    }
}

/// Keeps a reference to an `Image` instance and its duration as a GIF frame.
struct AnimatedFrame {
    var image: Image?
    let duration: TimeInterval
    
    static let null: AnimatedFrame = AnimatedFrame(image: .none, duration: 0.0)
}

// MARK: - Animator
class Animator {
    // MARK: Private property
    fileprivate let size: CGSize
    fileprivate let maxFrameCount: Int
    fileprivate let imageSource: CGImageSource
    
    fileprivate var animatedFrames = [AnimatedFrame]()
    fileprivate let maxTimeStep: TimeInterval = 1.0
    fileprivate var frameCount = 0
    fileprivate var currentFrameIndex = 0
    fileprivate var currentPreloadIndex = 0
    fileprivate var timeSinceLastFrameChange: TimeInterval = 0.0
    fileprivate var needsPrescaling = true
    
    /// Loop count of animatd image.
    private var loopCount = 0
    
    var currentFrame: UIImage? {
        return frame(at: currentFrameIndex)
    }
    
    var contentMode = UIViewContentMode.scaleToFill
    
    private lazy var preloadQueue: DispatchQueue = {
        return DispatchQueue(label: "com.onevcat.Kingfisher.Animator.preloadQueue")
    }()
    
    /**
     Init an animator with image source reference.
     
     - parameter imageSource: The reference of animated image.
     - parameter contentMode: Content mode of AnimatedImageView.
     - parameter size: Size of AnimatedImageView.
     - parameter framePreloadCount: Frame cache size.
     
     - returns: The animator object.
     */
    init(imageSource source: CGImageSource, contentMode mode: UIViewContentMode, size: CGSize, framePreloadCount count: Int) {
        self.imageSource = source
        self.contentMode = mode
        self.size = size
        self.maxFrameCount = count
    }
    
    func frame(at index: Int) -> Image? {
        return animatedFrames[safe: index]?.image
    }
    
    func prepareFramesAsynchronously() {
        preloadQueue.async { [weak self] in
            self?.prepareFrames()
        }
    }
    
    private func prepareFrames() {
        frameCount = CGImageSourceGetCount(imageSource)
        
        if let properties = CGImageSourceCopyProperties(imageSource, nil),
            let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
            let loopCount = gifInfo[kCGImagePropertyGIFLoopCount as String] as? Int
        {
            self.loopCount = loopCount
        }
        
        let frameToProcess = min(frameCount, maxFrameCount)
        animatedFrames.reserveCapacity(frameToProcess)
        animatedFrames = (0..<frameToProcess).reduce([]) { $0 + pure(prepareFrame(at: $1))}
        currentPreloadIndex = (frameToProcess + 1) % frameCount
    }
    
    private func prepareFrame(at index: Int) -> AnimatedFrame {
        
        guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
            return AnimatedFrame.null
        }
        
        let defaultGIFFrameDuration = 0.100
        let frameDuration = imageSource.kf.gifProperties(at: index).map {
            gifInfo -> Double in
            
            let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as Double?
            let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as Double?
            let duration = unclampedDelayTime ?? delayTime ?? 0.0
            
            /**
             http://opensource.apple.com/source/WebCore/WebCore-7600.1.25/platform/graphics/cg/ImageSourceCG.cpp
             Many annoying ads specify a 0 duration to make an image flash as quickly as
             possible. We follow Safari and Firefox's behavior and use a duration of 100 ms
             for any frames that specify a duration of <= 10 ms.
             See <rdar://problem/7689300> and <http://webkit.org/b/36082> for more information.
             
             See also: http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser.
             */
            return duration > 0.011 ? duration : defaultGIFFrameDuration
        } ?? defaultGIFFrameDuration
        
        let image = Image(cgImage: imageRef)
        let scaledImage: Image?
        
        if needsPrescaling {
            scaledImage = image.kf.resize(to: size, for: contentMode)
        } else {
            scaledImage = image
        }
        
        return AnimatedFrame(image: scaledImage, duration: frameDuration)
    }
    
    /**
     Updates the current frame if necessary using the frame timer and the duration of each frame in `animatedFrames`.
     */
    func updateCurrentFrame(duration: CFTimeInterval) -> Bool {
        timeSinceLastFrameChange += min(maxTimeStep, duration)
        guard let frameDuration = animatedFrames[safe: currentFrameIndex]?.duration, frameDuration <= timeSinceLastFrameChange else {
            return false
        }
        
        timeSinceLastFrameChange -= frameDuration
        
        let lastFrameIndex = currentFrameIndex
        currentFrameIndex += 1
        currentFrameIndex = currentFrameIndex % animatedFrames.count
        
        if animatedFrames.count < frameCount {
            preloadFrameAsynchronously(at: lastFrameIndex)
        }
        return true
    }
    
    private func preloadFrameAsynchronously(at index: Int) {
        preloadQueue.async { [weak self] in
            self?.preloadFrame(at: index)
        }
    }
    
    private func preloadFrame(at index: Int) {
        animatedFrames[index] = prepareFrame(at: currentPreloadIndex)
        currentPreloadIndex += 1
        currentPreloadIndex = currentPreloadIndex % frameCount
    }
}

extension CGImageSource: KingfisherCompatible { }
extension Kingfisher where Base: CGImageSource {
    func gifProperties(at index: Int) -> [String: Double]? {
        let properties = CGImageSourceCopyPropertiesAtIndex(base, index, nil) as Dictionary?
        return properties?[kCGImagePropertyGIFDictionary] as? [String: Double]
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}

private func pure<T>(_ value: T) -> [T] {
    return [value]
}
