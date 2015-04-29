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
*	Set image to use from web for a specified state.
*/
public extension UIButton {
    /**
    Set an image to use for a specified state with a URL.
    It will ask for Kingfisher's manager to get the image for the URL and then set it for a button state.
    The memory and disk will be searched first. If the manager does not find it, it will try to download the image at this URL and store it for next use.
    
    :param: URL   The URL of image for specified state.
    :param: state The state that uses the specified image.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image to use for a specified state with a URL and a placeholder image.
    
    :param: URL              The URL of image for specified state.
    :param: state            The state that uses the specified image.
    :param: placeholderImage A placeholder image when retrieving the image at URL.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image to use for a specified state with a URL, a placeholder image and options.
    
    :param: URL              The URL of image for specified state.
    :param: state            The state that uses the specified image.
    :param: placeholderImage A placeholder image when retrieving the image at URL.
    :param: optionsInfo      A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image to use for a specified state with a URL, a placeholder image, options and completion handler.
    
    :param: URL               The URL of image for specified state.
    :param: state             The state that uses the specified image.
    :param: placeholderImage  A placeholder image when retrieving the image at URL.
    :param: optionsInfo       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    :param: completionHandler Called when the image retrieved and set.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: completionHandler)
    }
    
    /**
    Set an image to use for a specified state with a URL, a placeholder image, options, progress handler and completion handler.
    
    :param: URL               The URL of image for specified state.
    :param: state             The state that uses the specified image.
    :param: placeholderImage  A placeholder image when retrieving the image at URL.
    :param: optionsInfo       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    :param: progressBlock     Called when the image downloading progress gets updated.
    :param: completionHandler Called when the image retrieved and set.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?,
                         progressBlock: DownloadProgressBlock?,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        setImage(placeholderImage, forState: state)
        kf_setWebURL(URL, forState: state)
        let task = KingfisherManager.sharedManager.retrieveImageWithURL(URL, optionsInfo: optionsInfo, progressBlock: { (receivedSize, totalSize) -> () in
            if let progressBlock = progressBlock {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                })
            }
        }) { (image, error, cacheType, imageURL) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if (imageURL == self.kf_webURLForState(state) && image != nil) {
                    self.setImage(image, forState: state)
                }
                completionHandler?(image: image, error: error, cacheType: cacheType, imageURL: imageURL)
            })
        }
        
        return task
    }
}

private var lastURLKey: Void?
public extension UIButton {
    /**
    Get the image URL binded to this button for a specified state. 
    
    :param: state The state that uses the specified image.
    
    :returns: Current URL for image.
    */
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

/**
*	Set background image to use from web for a specified state.
*/
public extension UIButton {
    /**
    Set the background image to use for a specified state with a URL.
    It will ask for Kingfisher's manager to get the image for the URL and then set it for a button state.
    The memory and disk will be searched first. If the manager does not find it, it will try to download the image at this URL and store it for next use.
    
    :param: URL   The URL of image for specified state.
    :param: state The state that uses the specified image.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set the background image to use for a specified state with a URL and a placeholder image.
    
    :param: URL              The URL of image for specified state.
    :param: state            The state that uses the specified image.
    :param: placeholderImage A placeholder image when retrieving the image at URL.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set the background image to use for a specified state with a URL, a placeholder image and options.
    
    :param: URL              The URL of image for specified state.
    :param: state            The state that uses the specified image.
    :param: placeholderImage A placeholder image when retrieving the image at URL.
    :param: optionsInfo      A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set the background image to use for a specified state with a URL, a placeholder image, options and completion handler.
    
    :param: URL               The URL of image for specified state.
    :param: state             The state that uses the specified image.
    :param: placeholderImage  A placeholder image when retrieving the image at URL.
    :param: optionsInfo       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    :param: completionHandler Called when the image retrieved and set.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: completionHandler)
    }
    
    /**
    Set the background image to use for a specified state with a URL, 
    a placeholder image, options progress handler and completion handler.
    
    :param: URL               The URL of image for specified state.
    :param: state             The state that uses the specified image.
    :param: placeholderImage  A placeholder image when retrieving the image at URL.
    :param: optionsInfo       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    :param: progressBlock     Called when the image downloading progress gets updated.
    :param: completionHandler Called when the image retrieved and set.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?,
                                   progressBlock: DownloadProgressBlock?,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        setBackgroundImage(placeholderImage, forState: state)
        kf_setBackgroundWebURL(URL, forState: state)
        let task = KingfisherManager.sharedManager.retrieveImageWithURL(URL, optionsInfo: optionsInfo, progressBlock: { (receivedSize, totalSize) -> () in
            if let progressBlock = progressBlock {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                })
            }
            }) { (image, error, cacheType, imageURL) -> () in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if (imageURL == self.kf_backgroundWebURLForState(state) && image != nil) {
                        self.setBackgroundImage(image, forState: state)
                    }
                    completionHandler?(image: image, error: error, cacheType: cacheType, imageURL: imageURL)
                })
        }
        
        return task
    }
}

private var lastBackgroundURLKey: Void?
public extension UIButton {
    /**
    Get the background image URL binded to this button for a specified state.
    
    :param: state The state that uses the specified background image.
    
    :returns: Current URL for background image.
    */
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

// MARK: - Deprecated
public extension UIButton {
    @availability(*, deprecated=1.2, message="Use -kf_setImageWithURL:forState:placeholderImage:optionsInfo: instead.")
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: [.Options: options], progressBlock: nil, completionHandler: nil)
    }
    
    @availability(*, deprecated=1.2, message="Use -kf_setImageWithURL:forState:placeholderImage:optionsInfo:completionHandler: instead.")
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: [.Options: options], progressBlock: nil, completionHandler: completionHandler)
    }
    
    @availability(*, deprecated=1.2, message="Use -kf_setImageWithURL:forState:placeholderImage:optionsInfo:progressBlock:completionHandler: instead.")
    public func kf_setImageWithURL(URL: NSURL,
                        forState state: UIControlState,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions,
                         progressBlock: DownloadProgressBlock?,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: [.Options: options], progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    @availability(*, deprecated=1.2, message="Use -kf_setBackgroundImageWithURL:forState:placeholderImage:optionsInfo: instead.")
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                         options: KingfisherOptions) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: [.Options: options], progressBlock: nil, completionHandler: nil)
    }
    
    @availability(*, deprecated=1.2, message="Use -kf_setBackgroundImageWithURL:forState:placeholderImage:optionsInfo:completionHandler: instead.")
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                         options: KingfisherOptions,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: [.Options: options], progressBlock: nil, completionHandler: completionHandler)
    }
    
    
    @availability(*, deprecated=1.2, message="Use -kf_setBackgroundImageWithURL:forState:placeholderImage:optionsInfo:progressBlock:completionHandler: instead.")
    public func kf_setBackgroundImageWithURL(URL: NSURL,
                                  forState state: UIControlState,
                                placeholderImage: UIImage?,
                                         options: KingfisherOptions,
                                   progressBlock: DownloadProgressBlock?,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setBackgroundImageWithURL(URL, forState: state, placeholderImage: placeholderImage, optionsInfo: [.Options: options], progressBlock: progressBlock, completionHandler: completionHandler)
    }
}

