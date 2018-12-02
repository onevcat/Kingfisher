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
//  Copyright (c) 2018 Reda Lemeden.
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

/// Protocol of `AnimatedImageView`.
public protocol AnimatedImageViewDelegate: AnyObject {

    /// Called after the animatedImageView has finished each animation loop.
    ///
    /// - Parameters:
    ///   - imageView: The `AnimatedImageView` that is being animated.
    ///   - count: The looped count.
    func animatedImageView(_ imageView: AnimatedImageView, didPlayAnimationLoops count: UInt)

    /// Called after the `AnimatedImageView` has reached the max repeat count.
    ///
    /// - Parameter imageView: The `AnimatedImageView` that is being animated.
    func animatedImageViewDidFinishAnimating(_ imageView: AnimatedImageView)
}

extension AnimatedImageViewDelegate {
    public func animatedImageView(_ imageView: AnimatedImageView, didPlayAnimationLoops count: UInt) {}
    public func animatedImageViewDidFinishAnimating(_ imageView: AnimatedImageView) {}
}

#if swift(>=4.2)
let KFRunLoopModeCommon = RunLoop.Mode.common
#else
let KFRunLoopModeCommon = RunLoopMode.commonModes
#endif

/// Represents a subclass of `UIImageView` for displaying animated image.
/// Different from showing animated image in a normal `UIImageView` (which load all frames at one time),
/// `AnimatedImageView` only tries to load several frames (defined by `framePreloadCount`) to reduce memory usage.
/// It provides a tradeoff between memory usage and CPU time. If you have a memory issue when using a normal image
/// view to load GIF data, you could give this class a try.
///
/// Kingfisher supports setting GIF animated data to either `UIImageView` and `AnimatedImageView` out of box. So
/// it would be fairly easy to switch between them.
open class AnimatedImageView: UIImageView {
    
    /// Proxy object for preventing a reference cycle between the `CADDisplayLink` and `AnimatedImageView`.
    class TargetProxy {
        private weak var target: AnimatedImageView?
        
        init(target: AnimatedImageView) {
            self.target = target
        }
        
        @objc func onScreenUpdate() {
            target?.updateFrame()
        }
    }

    /// Enumeration that specifies repeat count of GIF
    public enum RepeatCount: Equatable {
        case once
        case finite(count: UInt)
        case infinite

        public static func ==(lhs: RepeatCount, rhs: RepeatCount) -> Bool {
            switch (lhs, rhs) {
            case let (.finite(l), .finite(r)):
                return l == r
            case (.once, .once),
                 (.infinite, .infinite):
                return true
            case (.once, .finite(let count)),
                 (.finite(let count), .once):
                return count == 1
            case (.once, _),
                 (.infinite, _),
                 (.finite, _):
                return false
            }
        }
    }
    
    // MARK: - Public property
    /// Whether automatically play the animation when the view become visible. Default is `true`.
    public var autoPlayAnimatedImage = true
    
    /// The count of the frames should be preloaded before shown.
    public var framePreloadCount = 10
    
    /// Specifies whether the GIF frames should be pre-scaled to the image view's size or not.
    /// If the downloaded image is larger than the image view's size, it will help to reduce some memory use.
    /// Default is `true`.
    public var needsPrescaling = true

    /// The animation timer's run loop mode. Default is `RunLoop.Mode.common`.
    /// Set this property to `RunLoop.Mode.default` will make the animation pause during UIScrollView scrolling.
    public var runLoopMode = KFRunLoopModeCommon {
        willSet {
            guard runLoopMode == newValue else { return }
            stopAnimating()
            displayLink.remove(from: .main, forMode: runLoopMode)
            displayLink.add(to: .main, forMode: newValue)
            startAnimating()
        }
    }
    
    /// The repeat count. The animated image will keep animate until it the loop count reaches this value.
    /// Setting this value to another one will reset current animation.
    ///
    /// Default is `.infinite`, which means the animation will last forever.
    public var repeatCount = RepeatCount.infinite {
        didSet {
            if oldValue != repeatCount {
                reset()
                setNeedsDisplay()
                layer.setNeedsDisplay()
            }
        }
    }

    /// Delegate of this `AnimatedImageView` object. See `AnimatedImageViewDelegate` protocol for more.
    public weak var delegate: AnimatedImageViewDelegate?
    
    // MARK: - Private property
    /// `Animator` instance that holds the frames of a specific image in memory.
    private var animator: Animator?
    
    // A flag to avoid invalidating the displayLink on deinit if it was never created, because displayLink is so lazy.
    private var isDisplayLinkInitialized: Bool = false
    
    // A display link that keeps calling the `updateFrame` method on every screen refresh.
    private lazy var displayLink: CADisplayLink = {
        isDisplayLinkInitialized = true
        let displayLink = CADisplayLink(target: TargetProxy(target: self), selector: #selector(TargetProxy.onScreenUpdate))
        displayLink.add(to: .main, forMode: runLoopMode)
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
        guard !isAnimating else { return }
        if animator?.isReachMaxRepeatCount ?? false {
            return
        }

        displayLink.isPaused = false
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

    // This is for back compatibility that using regular `UIImageView` to show animated image.
    override func shouldPreloadAllAnimation() -> Bool {
        return false
    }

    // Reset the animator.
    private func reset() {
        animator = nil
        if let imageSource = image?.kf.imageSource {
            let animator = Animator(
                imageSource: imageSource,
                contentMode: contentMode,
                size: bounds.size,
                framePreloadCount: framePreloadCount,
                repeatCount: repeatCount)
            animator.delegate = self
            animator.needsPrescaling = needsPrescaling
            animator.prepareFramesAsynchronously()
            self.animator = animator
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
        let duration: CFTimeInterval

        // CA based display link is opt-out from ProMotion by default.
        // So the duration and its FPS might not match. 
        // See [#718](https://github.com/onevcat/Kingfisher/issues/718)
        // By setting CADisableMinimumFrameDuration to YES in Info.plist may
        // cause the preferredFramesPerSecond being 0
        if displayLink.preferredFramesPerSecond == 0 {
            duration = displayLink.duration
        } else {
            // Some devices (like iPad Pro 10.5) will have a different FPS.
            duration = 1.0 / Double(displayLink.preferredFramesPerSecond)
        }
    
        if animator?.updateCurrentFrame(duration: duration) ?? false {
            layer.setNeedsDisplay()

            if animator?.isReachMaxRepeatCount ?? false {
                stopAnimating()
                delegate?.animatedImageViewDidFinishAnimating(self)
            }
        }
    }
}

extension AnimatedImageView: AnimatorDelegate {
    func animator(_ animator: Animator, didPlayAnimationLoops count: UInt) {
        delegate?.animatedImageView(self, didPlayAnimationLoops: count)
    }
}

/// Keeps a reference to an `Image` instance and its duration as a GIF frame.
struct AnimatedFrame {
    var image: Image?
    let duration: TimeInterval
    
    static let null = AnimatedFrame(image: .none, duration: 0.0)
}

protocol AnimatorDelegate: AnyObject {
    func animator(_ animator: Animator, didPlayAnimationLoops count: UInt)
}

// MARK: - Animator
class Animator {
    // MARK: Private property
    private let size: CGSize
    private let maxFrameCount: Int
    private let imageSource: CGImageSource
    private let maxRepeatCount: AnimatedImageView.RepeatCount
    
    private var animatedFrames = [AnimatedFrame]()
    private let maxTimeStep: TimeInterval = 1.0
    private var frameCount = 0
    private var currentFrameIndex = 0
    private var currentFrameIndexInBuffer = 0
    private var currentPreloadIndex = 0
    private var timeSinceLastFrameChange: TimeInterval = 0.0
    private var currentRepeatCount: UInt = 0
    
    var needsPrescaling = true
    weak var delegate: AnimatorDelegate?
    
    /// Loop count of animated image.
    private var loopCount = 0
    
    var currentFrame: UIImage? {
        return frame(at: currentFrameIndexInBuffer)
    }

    var isReachMaxRepeatCount: Bool {
        switch maxRepeatCount {
        case .once:
            return currentRepeatCount >= 1
        case .finite(let maxCount):
            return currentRepeatCount >= maxCount
        case .infinite:
            return false
        }
    }
    
    var contentMode = UIView.ContentMode.scaleToFill
    
    private lazy var preloadQueue: DispatchQueue = {
        return DispatchQueue(label: "com.onevcat.Kingfisher.Animator.preloadQueue")
    }()
    
    /// Creates an animator with image source reference.
    ///
    /// - Parameters:
    ///   - source: The reference of animated image.
    ///   - mode: Content mode of the `AnimatedImageView`.
    ///   - size: Size of the `AnimatedImageView`.
    ///   - count: Count of frames needed to be preloaded.
    ///   - repeatCount: The repeat count should this animator uses.
    init(imageSource source: CGImageSource,
         contentMode mode: UIView.ContentMode,
         size: CGSize,
         framePreloadCount count: Int,
         repeatCount: AnimatedImageView.RepeatCount) {
        self.imageSource = source
        self.contentMode = mode
        self.size = size
        self.maxFrameCount = count
        self.maxRepeatCount = repeatCount
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
        currentPreloadIndex = (frameToProcess + 1) % frameCount - 1
    }
    
    private func prepareFrame(at index: Int) -> AnimatedFrame {
        
        guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
            return .null
        }
        
        let defaultGIFFrameDuration = 0.100
        let frameDuration = imageSource.gifProperties(at: index).map {
            gifInfo -> Double in
            
            let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as Double?
            let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as Double?
            let duration = unclampedDelayTime ?? delayTime ?? 0.0
            
            /*
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
    
    /// Updates the current frame if necessary using the frame timer and the duration of each frame in `animatedFrames`.
    func updateCurrentFrame(duration: CFTimeInterval) -> Bool {
        timeSinceLastFrameChange += min(maxTimeStep, duration)
        guard let frameDuration = animatedFrames[safe: currentFrameIndexInBuffer]?.duration, frameDuration <= timeSinceLastFrameChange else {
            return false
        }
        
        timeSinceLastFrameChange -= frameDuration
        
        let lastFrameIndex = currentFrameIndexInBuffer
        currentFrameIndexInBuffer += 1
        currentFrameIndexInBuffer = currentFrameIndexInBuffer % animatedFrames.count
        
        if animatedFrames.count < frameCount {
            preloadFrameAsynchronously(at: lastFrameIndex)
        }
        
        currentFrameIndex += 1
        
        if currentFrameIndex == frameCount {
            currentFrameIndex = 0
            currentRepeatCount += 1

            delegate?.animator(self, didPlayAnimationLoops: currentRepeatCount)
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

extension CGImageSource {
    func gifProperties(at index: Int) -> [String: Double]? {
        let properties = CGImageSourceCopyPropertiesAtIndex(self, index, nil) as Dictionary?
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
