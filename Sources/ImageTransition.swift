//
//  ImageTransition.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/9/18.
//
//  Copyright (c) 2018 Wei Wang <onevcat@gmail.com>
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
// Not implemented for macOS and watchOS yet.
    
import AppKit

/// Image transition is not supported on macOS.
public enum ImageTransition {
    case none
    var duration: TimeInterval {
        return 0
    }
}

#elseif os(watchOS)
import UIKit
/// Image transition is not supported on watchOS.
public enum ImageTransition {
    case none
    var duration: TimeInterval {
        return 0
    }
}
#else
import UIKit

/**
Transition effect which will be used when an image downloaded and set by `UIImageView` extension API in Kingfisher.
You can assign an enum value with transition duration as an item in `KingfisherOptionsInfo` 
to enable the animation transition.

Apple's UIViewAnimationOptions is used under the hood.
For custom transition, you should specified your own transition options, animations and 
completion handler as well.
*/
public enum ImageTransition {
    ///  No animation transition.
    case none
    
    /// Fade in the loaded image.
    case fade(TimeInterval)

    /// Flip from left transition.
    case flipFromLeft(TimeInterval)

    /// Flip from right transition.
    case flipFromRight(TimeInterval)
    
    /// Flip from top transition.
    case flipFromTop(TimeInterval)
    
    /// Flip from bottom transition.
    case flipFromBottom(TimeInterval)
    
    /// Custom transition.
    case custom(duration: TimeInterval,
                 options: UIViewAnimationOptions,
              animations: ((UIImageView, UIImage) -> Void)?,
              completion: ((Bool) -> Void)?)
    
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
    
    var animationOptions: UIViewAnimationOptions {
        switch self {
        case .none:                         return []
        case .fade(_):                      return .transitionCrossDissolve
            
        case .flipFromLeft(_):              return .transitionFlipFromLeft
        case .flipFromRight(_):             return .transitionFlipFromRight
        case .flipFromTop(_):               return .transitionFlipFromTop
        case .flipFromBottom(_):            return .transitionFlipFromBottom
            
        case .custom(_, let options, _, _): return options
        }
    }
    
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
#endif
