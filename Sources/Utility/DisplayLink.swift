//
//  DisplayLink.swift
//  Kingfisher
//
//  Created by yeatse on 2024/1/9.
//
//  Copyright (c) 2024 Wei Wang <onevcat@gmail.com>
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
#if canImport(UIKit)
import UIKit
#else
import AppKit
import CoreVideo
#endif

protocol DisplayLinkCompatible: AnyObject {
    var isPaused: Bool { get set }
    
    var preferredFramesPerSecond: NSInteger { get }
    var timestamp: CFTimeInterval { get }
    var duration: CFTimeInterval { get }
    
    func add(to runLoop: RunLoop, forMode mode: RunLoop.Mode)
    func remove(from runLoop: RunLoop, forMode mode: RunLoop.Mode)
    
    func invalidate()
}

#if !os(macOS)
extension UIView {
    func compatibleDisplayLink(target: Any, selector: Selector) -> DisplayLinkCompatible {
        return CADisplayLink(target: target, selector: selector)
    }
}

extension CADisplayLink: DisplayLinkCompatible {}

#else
extension NSView {
    func compatibleDisplayLink(target: Any, selector: Selector) -> DisplayLinkCompatible {
#if swift(>=5.9) // macOS 14 SDK is included in Xcode 15, which comes with swift 5.9. Add this check to make old compilers happy.
        if #available(macOS 14.0, *) {
            return displayLink(target: target, selector: selector)
        } else {
            return DisplayLink(target: target, selector: selector)
        }
#else
        return DisplayLink(target: target, selector: selector)
#endif
    }
}

#if swift(>=5.9)
@available(macOS 14.0, *)
extension CADisplayLink: DisplayLinkCompatible {
    var preferredFramesPerSecond: NSInteger { return 0 }
}
#endif

class DisplayLink: DisplayLinkCompatible {
    private var link: CVDisplayLink?
    private var target: Any?
    private var selector: Selector?
    
    private var schedulers: [RunLoop: [RunLoop.Mode]] = [:]
    
    init(target: Any, selector: Selector) {
        self.target = target
        self.selector = selector
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        if let link = link {
            CVDisplayLinkSetOutputHandler(link, displayLinkCallback(_:inNow:inOutputTime:flagsIn:flagsOut:))
        }
    }
    
    deinit {
        self.invalidate()
    }
    
    private func displayLinkCallback(_ link: CVDisplayLink,
                                     inNow: UnsafePointer<CVTimeStamp>,
                                     inOutputTime: UnsafePointer<CVTimeStamp>,
                                     flagsIn: CVOptionFlags,
                                     flagsOut: UnsafeMutablePointer<CVOptionFlags>) -> CVReturn
    {
        let outputTime = inOutputTime.pointee
        DispatchQueue.main.async {
            guard let selector = self.selector, let target = self.target else { return }
            if outputTime.videoTimeScale != 0 {
                self.duration = CFTimeInterval(Double(outputTime.videoRefreshPeriod) / Double(outputTime.videoTimeScale))
            }
            if self.timestamp != 0 {
                for scheduler in self.schedulers {
                    scheduler.key.perform(selector, target: target, argument: nil, order: 0, modes: scheduler.value)
                }
            }
            self.timestamp = CFTimeInterval(Double(outputTime.hostTime) / 1_000_000_000)
        }
        return kCVReturnSuccess
    }
    
    var isPaused: Bool = true {
        didSet {
            guard let link = link else { return }
            if isPaused {
                if CVDisplayLinkIsRunning(link) {
                    CVDisplayLinkStop(link)
                }
            } else {
                if !CVDisplayLinkIsRunning(link) {
                    CVDisplayLinkStart(link)
                }
            }
        }
    }
    
    var preferredFramesPerSecond: NSInteger = 0
    var timestamp: CFTimeInterval = 0
    var duration: CFTimeInterval = 0
    
    func add(to runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        assert(runLoop == .main)
        schedulers[runLoop, default: []].append(mode)
    }
    
    func remove(from runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        schedulers[runLoop]?.removeAll { $0 == mode }
        if let modes = schedulers[runLoop], modes.isEmpty {
            schedulers.removeValue(forKey: runLoop)
        }
    }
    
    func invalidate() {
        schedulers = [:]
        isPaused = true
        target = nil
        selector = nil
        if let link = link {
            CVDisplayLinkSetOutputHandler(link) { _, _, _, _, _ in kCVReturnSuccess }
        }
    }
}
#endif
#endif
