//
//  UIButton+Kingfisher.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/13.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
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

/**
*	Set image for state
*/
public extension UIButton {
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeHolderImage: nil, options: KingfisherOptions.None, progressBlock: nil, completionHandler: nil)
    }
    
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeHolderImage: placeHolderImage, options: KingfisherOptions.None, progressBlock: nil, completionHandler: nil)
    }
    
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeHolderImage: placeHolderImage, options: options, progressBlock: nil, completionHandler: nil)
    }
    
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeHolderImage: placeHolderImage, options: options, progressBlock: nil, completionHandler: completionHandler)
    }
    
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions,
                         progressBlock: DownloadProgressBlock?,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        setImage(placeHolderImage, forState: state)
        let task = KingfisherManager.sharedManager.retrieveImageWithURL(URL, options: options, progressBlock: { (receivedSize, totalSize) -> () in
            if let progressBlock = progressBlock {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                })
            }
        }) { (image, error, imageURL) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if (imageURL == self.kf_webURLForState(state) && image != nil) {
                    self.setImage(image, forState: state)
                }
                completionHandler?(image: image, error: error, imageURL: imageURL)
            })
        }
        
        return task
    }
}

private var lastURLKey: Void?
public extension UIButton {
    public func kf_webURLForState(state: UIControlState) -> NSURL? {
        return kf_webURLs[NSNumber(unsignedLong:state.rawValue)] as? NSURL
    }
    
    private func kf_setWebURL(URL: NSURL, forState state: UIControlState) {
        kf_webURLs[NSNumber(unsignedLong:state.rawValue)] = URL
    }
    
    private var kf_webURLs: NSMutableDictionary {
        get {
            var dictionary = objc_getAssociatedObject(self, &lastURLKey) as? NSMutableDictionary
            if dictionary == nil {
                dictionary = NSMutableDictionary()
                kf_setWebURLs(dictionary!)
            }
            return dictionary!
        }
    }
    
    private func kf_setWebURLs(URLs: NSMutableDictionary) {
        objc_setAssociatedObject(self, &lastURLKey, URLs, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
}

public extension UIButton {
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeHolderImage: nil, options: KingfisherOptions.None, progressBlock: nil, completionHandler: nil)
    }
    
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeHolderImage: UIImage?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeHolderImage: placeHolderImage, options: KingfisherOptions.None, progressBlock: nil, completionHandler: nil)
    }
    
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeHolderImage: UIImage?,
                                         options: KingfisherOptions) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeHolderImage: placeHolderImage, options: options, progressBlock: nil, completionHandler: nil)
    }
    
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeHolderImage: UIImage?,
                                         options: KingfisherOptions,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeHolderImage: placeHolderImage, options: options, progressBlock: nil, completionHandler: completionHandler)
    }
    
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeHolderImage: UIImage?,
                                         options: KingfisherOptions,
                                   progressBlock: DownloadProgressBlock?,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        setBackgroundImage(placeHolderImage, forState: state)
        let task = KingfisherManager.sharedManager.retrieveImageWithURL(URL, options: options, progressBlock: { (receivedSize, totalSize) -> () in
            if let progressBlock = progressBlock {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                })
            }
            }) { (image, error, imageURL) -> () in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if (imageURL == self.kf_webURLForState(state) && image != nil) {
                        self.setBackgroundImage(image, forState: state)
                    }
                    completionHandler?(image: image, error: error, imageURL: imageURL)
                })
        }
        
        return task
    }
}

private var lastBackgroundURLKey: Void?
public extension UIButton {
    public func kf_backgroundWebURLForState(state: UIControlState) -> NSURL? {
        return kf_backgroundWebURLs[NSNumber(unsignedLong:state.rawValue)] as? NSURL
    }
    
    private func kf_setBackgroundWebURL(URL: NSURL, forState state: UIControlState) {
        kf_backgroundWebURLs[NSNumber(unsignedLong:state.rawValue)] = URL
    }
    
    private var kf_backgroundWebURLs: NSMutableDictionary {
        get {
            var dictionary = objc_getAssociatedObject(self, &lastBackgroundURLKey) as? NSMutableDictionary
            if dictionary == nil {
                dictionary = NSMutableDictionary()
                kf_setBackgroundWebURLs(dictionary!)
            }
            return dictionary!
        }
    }
    
    private func kf_setBackgroundWebURLs(URLs: NSMutableDictionary) {
        objc_setAssociatedObject(self, &lastBackgroundURLKey, URLs, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
}


