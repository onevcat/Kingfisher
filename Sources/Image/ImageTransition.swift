//
//  ImageTransition.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/9/18.
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

import Foundation
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

/// Transition effect to be used when an image is downloaded and set using the `UIImageView` extension API in Kingfisher.
///
/// You can assign an enum value with a transition duration as an item in `KingfisherOptionsInfo` to enable the animation
/// transition. Apple's `UIViewAnimationOptions` are used under the hood.
///
/// For custom transitions, you should specify your own transition options, animations, and completion handler as well.
public enum ImageTransition: Sendable {
    /// No animation transition.
    case none
    /// Fade effect to the loaded image over a specified duration.
    case fade(TimeInterval)
    /// Flip from left transition.
    case flipFromLeft(TimeInterval)
    /// Flip from right transition.
    case flipFromRight(TimeInterval)
    /// Flip from top transition.
    case flipFromTop(TimeInterval)
    /// Flip from bottom transition.
    case flipFromBottom(TimeInterval)
    /// Custom transition defined by a general animation block.
    ///
    /// - Parameters:
    ///    - duration: The duration of this custom transition.
    ///    - options: The `UIView.AnimationOptions` to use in the transition.
    ///    - animations: The animation block to apply when setting the image.
    ///    - completion: A block called when the transition animation finishes.
    case custom(duration: TimeInterval,
                 options: UIView.AnimationOptions,
              animations: (@Sendable @MainActor (UIImageView, UIImage) -> Void)?,
              completion: (@Sendable (Bool) -> Void)?)
    
    var duration: TimeInterval {
        switch self {
        case .none:                          return 0
        case .fade(let duration):            return duration
            
        case .flipFromLeft(let duration):    return duration
        case .flipFromRight(let duration):   return duration
        case .flipFromTop(let duration):     return duration
        case .flipFromBottom(let duration):  return duration
            
        case .custom(let duration, _, _, _): return duration
        }
    }
    
    var animationOptions: UIView.AnimationOptions {
        switch self {
        case .none:                         return []
        case .fade:                         return .transitionCrossDissolve
            
        case .flipFromLeft:                 return .transitionFlipFromLeft
        case .flipFromRight:                return .transitionFlipFromRight
        case .flipFromTop:                  return .transitionFlipFromTop
        case .flipFromBottom:               return .transitionFlipFromBottom
            
        case .custom(_, let options, _, _): return options
        }
    }
    
    @MainActor
    var animations: ((UIImageView, UIImage) -> Void)? {
        switch self {
        case .custom(_, _, let animations, _): return animations
        default: return { $0.image = $1 }
        }
    }
    
    var completion: ((Bool) -> Void)? {
        switch self {
        case .custom(_, _, _, let completion): return completion
        default: return nil
        }
    }
}
#else
// Just a placeholder for compiling on macOS.
public enum ImageTransition: Sendable {
    case none
    /// This is a placeholder on macOS now. It is for SwiftUI (KFImage) to identify the fade option only.
    case fade(TimeInterval)
}
#endif
