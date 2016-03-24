//
//  ImageView+GifAnimation.swift
//
//  Created by michael yan wang on 3/23/16.
//  Homepage:   http://www.wangyan.im
//  Twitter:    https://twitter.com/xiaoxiaocainiao
//

import UIKit

private var animationImagesKey: Void?
private var animationDurationKey: Void?

extension UIImageView {
    
    #if os(OSX)
    
    //i know nothing about OSX sdk...
    
    #else
    
    /// Get the images duration to this image.
    private var kf_animationDuration: NSTimeInterval? {
        return objc_getAssociatedObject(self, &animationDurationKey) as? NSTimeInterval
    }
    
    private func kf_setAnimationDuration(duration: NSTimeInterval) -> Void
    {
        objc_setAssociatedObject(self, &animationDurationKey, duration, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    
    /// Get the images binded to this image.
    private var kf_animationImages: [UIImage]? {
        return objc_getAssociatedObject(self, &animationImagesKey) as? [UIImage]
    }
    
    private func kf_setAnimationImages(images: [UIImage]) {
        objc_setAssociatedObject(self, &animationImagesKey, images, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    
    // check image is animating or not
    public var kf_isAnimation: Bool{
    
        if  let _ = image?.images {
            return true
        } else {
            return false
        }
        
    }
    
    //animating the image if it's possible
    public func kf_startAnimation(){
        
        if kf_isAnimation {
            return
        }
        
        if let value = kf_animationImages
        {
            image = Image.animatedImageWithImages(value, duration: 0)
        }
        
    }
    
    //stop animating the image if it' possible
    public func kf_stopAnimation(){
        
        if kf_isAnimation
        {
            if let imagesValue = image?.images, let durationValue = image?.duration
            {
                kf_setAnimationImages(imagesValue)
                kf_setAnimationDuration(durationValue)
                
                if let firstFrame = imagesValue.first
                {
                    image = firstFrame
                }
            }
            
        }
    }
    
    #endif
}
