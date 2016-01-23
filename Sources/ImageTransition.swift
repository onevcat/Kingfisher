//
//  ImageTransition.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/9/18.
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
// Not implemented for OSX and watchOS yet.
    
import AppKit
    
public enum ImageTransition {
    case None
    var duration: NSTimeInterval {
        return 0
    }
}

#elseif os(watchOS)
import UIKit
public enum ImageTransition {
    case None
    var duration: NSTimeInterval {
        return 0
    }
}
#else
import UIKit

/**
Transition effect to use when an image downloaded and set by `UIImageView` extension API in Kingfisher.
You can assign an enum value with transition duration as an item in `KingfisherOptionsInfo` 
to enable the animation transition.

Apple's UIViewAnimationOptions is used under the hood.
For custom transition, you should specified your own transition options, animations and 
comletion handler as well.

- None:           No animation transistion.
- Fade:           Fade in the loaded image.
- FlipFromLeft:   Flip from left transition.
- FlipFromRight:  Flip from right transition.
- FlipFromTop:    Flip from top transition.
- FlipFromBottom: Flip from bottom transition.
- Custom:         Custom transition.
*/
public enum ImageTransition {
    case None
    case Fade(NSTimeInterval)

    case FlipFromLeft(NSTimeInterval)
    case FlipFromRight(NSTimeInterval)
    case FlipFromTop(NSTimeInterval)
    case FlipFromBottom(NSTimeInterval)
    
    case Custom(duration: NSTimeInterval,
                 options: UIViewAnimationOptions,
              animations: ((UIImageView, UIImage) -> Void)?,
              completion: ((Bool) -> Void)?)
    
    var duration: NSTimeInterval {
        switch self {
        case .None:                          return 0
        case .Fade(let duration):            return duration
            
        case .FlipFromLeft(let duration):    return duration
        case .FlipFromRight(let duration):   return duration
        case .FlipFromTop(let duration):     return duration
        case .FlipFromBottom(let duration):  return duration
            
        case .Custom(let duration, _, _, _): return duration
        }
    }
    
    var animationOptions: UIViewAnimationOptions {
        switch self {
        case .None:                         return .TransitionNone
        case .Fade(_):                      return .TransitionCrossDissolve
            
        case .FlipFromLeft(_):              return .TransitionFlipFromLeft
        case .FlipFromRight(_):             return .TransitionFlipFromRight
        case .FlipFromTop(_):               return .TransitionFlipFromTop
        case .FlipFromBottom(_):            return .TransitionFlipFromBottom
            
        case .Custom(_, let options, _, _): return options
        }
    }
    
    var animations: ((UIImageView, UIImage) -> Void)? {
        switch self {
        case .Custom(_, _, let animations, _): return animations
        default: return {$0.image = $1}
        }
    }
    
    var completion: ((Bool) -> Void)? {
        switch self {
        case .Custom(_, _, _, let completion): return completion
        default: return nil
        }
    }
}
#endif
