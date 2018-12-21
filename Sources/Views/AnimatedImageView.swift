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
            target?.updateFrameIfNeeded()
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

    // Dispatch queue used for preloading images.
    private lazy var preloadQueue: DispatchQueue = {
        return DispatchQueue(label: "com.onevcat.Kingfisher.Animator.preloadQueue")
    }()
    
    // A flag to avoid invalidating the displayLink on deinit if it was never created, because displayLink is so lazy.
    private var isDisplayLinkInitialized: Bool = false
    
    // A display link that keeps calling the `updateFrame` method on every screen refresh.
    private lazy var displayLink: CADisplayLink = {
        isDisplayLinkInitialized = true
        let displayLink = CADisplayLink(
            target: TargetProxy(target: self), selector: #selector(TargetProxy.onScreenUpdate))
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
        if let currentFrame = animator?.currentFrameImage {
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
                repeatCount: repeatCount,
                preloadQueue: preloadQueue)
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
    private func updateFrameIfNeeded() {
        guard let animator = animator else {
            return
        }

        guard !animator.isFinished else {
            stopAnimating()
            delegate?.animatedImageViewDidFinishAnimating(self)
            return
        }

        let duration: CFTimeInterval

        // CA based display link is opt-out from ProMotion by default.
        // So the duration and its FPS might not match. 
        // See [#718](https://github.com/onevcat/Kingfisher/issues/718)
        // By setting CADisableMinimumFrameDuration to YES in Info.plist may
        // cause the preferredFramesPerSecond being 0
        if #available(iOS 10.0, tvOS 10.0, *) {
            // By setting CADisableMinimumFrameDuration to YES in Info.plist may
            // cause the preferredFramesPerSecond being 0
            if displayLink.preferredFramesPerSecond == 0 {
                duration = displayLink.duration
            } else {
                // Some devices (like iPad Pro 10.5) will have a different FPS.
                duration = 1.0 / Double(displayLink.preferredFramesPerSecond)
            }
        } else {
            duration = displayLink.duration
        }

        animator.shouldChangeFrame(with: duration) { [weak self] hasNewFrame in
            if hasNewFrame {
                self?.layer.setNeedsDisplay()
            }
        }
    }
}

protocol AnimatorDelegate: AnyObject {
    func animator(_ animator: AnimatedImageView.Animator, didPlayAnimationLoops count: UInt)
}

extension AnimatedImageView: AnimatorDelegate {
    func animator(_ animator: Animator, didPlayAnimationLoops count: UInt) {
        delegate?.animatedImageView(self, didPlayAnimationLoops: count)
    }
}

extension AnimatedImageView {

    // Represents a single frame in a GIF.
    struct AnimatedFrame {

        // The image to display for this frame. Its value is nil when the frame is removed from the buffer.
        let image: UIImage?

        // The duration that this frame should remain active.
        let duration: TimeInterval

        // A placeholder frame with no image assigned.
        // Used to replace frames that are no longer needed in the animation.
        var placeholderFrame: AnimatedFrame {
            return AnimatedFrame(image: nil, duration: duration)
        }

        // Whether this frame instance contains an image or not.
        var isPlaceholder: Bool {
            return image == nil
        }

        // Returns a new instance from an optional image.
        //
        // - parameter image: An optional `UIImage` instance to be assigned to the new frame.
        // - returns: An `AnimatedFrame` instance.
        func makeAnimatedFrame(image: UIImage?) -> AnimatedFrame {
            return AnimatedFrame(image: image, duration: duration)
        }
    }
}

extension AnimatedImageView {

    // MARK: - Animator
    class Animator {
        private let size: CGSize
        private let maxFrameCount: Int
        private let imageSource: CGImageSource
        private let maxRepeatCount: RepeatCount

        private let maxTimeStep: TimeInterval = 1.0
        private var animatedFrames = [AnimatedFrame]()
        private var frameCount = 0
        private var timeSinceLastFrameChange: TimeInterval = 0.0
        private var currentRepeatCount: UInt = 0

        var isFinished: Bool = false

        var needsPrescaling = true
        weak var delegate: AnimatorDelegate?

        // Total duration of one animation loop
        var loopDuration: TimeInterval = 0

        // Current active frame image
        var currentFrameImage: UIImage? {
            return frame(at: currentFrameIndex)
        }

        // Current active frame duration
        var currentFrameDuration: TimeInterval {
            return duration(at: currentFrameIndex)
        }

        // The index of the current GIF frame.
        var currentFrameIndex = 0 {
            didSet {
                previousFrameIndex = oldValue
            }
        }

        var previousFrameIndex = 0 {
            didSet {
                preloadQueue.async {
                    self.updatePreloadedFrames()
                }
            }
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

        var isLastFrame: Bool {
            return currentFrameIndex == frameCount - 1
        }

        var preloadingIsNeeded: Bool {
            return maxFrameCount < frameCount - 1
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
             repeatCount: RepeatCount,
             preloadQueue: DispatchQueue) {
            self.imageSource = source
            self.contentMode = mode
            self.size = size
            self.maxFrameCount = count
            self.maxRepeatCount = repeatCount
            self.preloadQueue = preloadQueue
        }

        func frame(at index: Int) -> Image? {
            return animatedFrames[safe: index]?.image
        }

        func duration(at index: Int) -> TimeInterval {
            return animatedFrames[safe: index]?.duration  ?? .infinity
        }

        func prepareFramesAsynchronously() {
            frameCount = Int(CGImageSourceGetCount(imageSource))
            animatedFrames.reserveCapacity(frameCount)
            preloadQueue.async { [weak self] in
                self?.setupAnimatedFrames()
            }
        }

        func shouldChangeFrame(with duration: CFTimeInterval, handler: (Bool) -> Void) {
            incrementTimeSinceLastFrameChange(with: duration)

            if currentFrameDuration > timeSinceLastFrameChange {
                handler(false)
            } else {
                resetTimeSinceLastFrameChange()
                incrementCurrentFrameIndex()
                handler(true)
            }
        }

        private func setupAnimatedFrames() {
            resetAnimatedFrames()

            var duration: TimeInterval = 0

            (0..<frameCount).forEach { index in
                let frameDuration = GIFAnimatedImage.getFrameDuration(from: imageSource, at: index)
                duration += min(frameDuration, maxTimeStep)
                animatedFrames += [AnimatedFrame(image: nil, duration: frameDuration)]

                if index > maxFrameCount { return }
                animatedFrames[index] = animatedFrames[index].makeAnimatedFrame(image: loadFrame(at: index))
            }

            self.loopDuration = duration
        }

        private func resetAnimatedFrames() {
            animatedFrames = []
        }

        private func loadFrame(at index: Int) -> UIImage? {
            guard let image = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
                return nil
            }

            let scaledImage: CGImage
            if needsPrescaling, size != .zero {
                scaledImage = image.kf.resize(to: size, for: contentMode)
            } else {
                scaledImage = image
            }

            return Image(cgImage: scaledImage)
        }
        
        private func updatePreloadedFrames() {
            guard preloadingIsNeeded else {
                return
            }

            animatedFrames[previousFrameIndex] = animatedFrames[previousFrameIndex].placeholderFrame

            preloadIndexes(start: currentFrameIndex).forEach { index in
                let currentAnimatedFrame = animatedFrames[index]
                if !currentAnimatedFrame.isPlaceholder { return }
                animatedFrames[index] = currentAnimatedFrame.makeAnimatedFrame(image: loadFrame(at: index))
            }
        }

        private func incrementCurrentFrameIndex() {
            currentFrameIndex = increment(frameIndex: currentFrameIndex)
            if isReachMaxRepeatCount && isLastFrame {
                isFinished = true
            } else if currentFrameIndex == 0 {
                currentRepeatCount += 1
                delegate?.animator(self, didPlayAnimationLoops: currentRepeatCount)
            }
        }

        private func incrementTimeSinceLastFrameChange(with duration: TimeInterval) {
            timeSinceLastFrameChange += min(maxTimeStep, duration)
        }

        private func resetTimeSinceLastFrameChange() {
            timeSinceLastFrameChange -= currentFrameDuration
        }

        private func increment(frameIndex: Int, by value: Int = 1) -> Int {
            return (frameIndex + value) % frameCount
        }

        private func preloadIndexes(start index: Int) -> [Int] {
            let nextIndex = increment(frameIndex: index)
            let lastIndex = increment(frameIndex: index, by: maxFrameCount)

            if lastIndex >= nextIndex {
                return [Int](nextIndex...lastIndex)
            } else {
                return [Int](nextIndex..<frameCount) + [Int](0...lastIndex)
            }
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
