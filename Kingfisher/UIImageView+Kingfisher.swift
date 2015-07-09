//
//  UIImageView+Kingfisher.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
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

// MARK: - Set Images
/**
*	Set image to use from web.
*/
public extension UIImageView {
    /**
    Set an image with a URL.
    It will ask for Kingfisher's manager to get the image for the URL.
    The memory and disk will be searched first. If the manager does not find it, it will try to download the image at this URL and store it for next use.
    
    :param: URL The URL of image.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setImageWithURL(URL: NSURL) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a URL and a placeholder image.
    
    :param: URL              The URL of image.
    :param: placeholderImage A placeholder image when retrieving the image at URL.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a URL, a placaholder image and options.
    
    :param: URL              The URL of image.
    :param: placeholderImage A placeholder image when retrieving the image at URL.
    :param: optionsInfo      A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a URL, a placeholder image, options and completion handler.
    
    :param: URL               The URL of image.
    :param: placeholderImage  A placeholder image when retrieving the image at URL.
    :param: optionsInfo       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    :param: completionHandler Called when the image retrieved and set.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: completionHandler)
    }
    
    /**
    Set an image with a URL, a placeholder image, options, progress handler and completion handler.
    
    :param: URL               The URL of image.
    :param: placeholderImage  A placeholder image when retrieving the image at URL.
    :param: optionsInfo       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    :param: progressBlock     Called when the image downloading progress gets updated.
    :param: completionHandler Called when the image retrieved and set.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?,
                         progressBlock: DownloadProgressBlock?,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        image = placeholderImage
        
        kf_setWebURL(URL)
        let task = KingfisherManager.sharedManager.retrieveImageWithURL(URL, optionsInfo: optionsInfo, progressBlock: { (receivedSize, totalSize) -> () in
            if let progressBlock = progressBlock {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                })
            }
            }, completionHandler: {[weak self] (image, error, cacheType, imageURL) -> () in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let sSelf = self where imageURL == sSelf.kf_webURL && image != nil {
                        sSelf.image = image;
                    }
                    completionHandler?(image: image, error: error, cacheType:cacheType, imageURL: imageURL)
                })
            })
        
        return task
    }
}

// MARK: - Associated Object
private var lastURLkey: Void?
public extension UIImageView {
    /// Get the image URL binded to this image view.
    public var kf_webURL: NSURL? {
        get {
            return objc_getAssociatedObject(self, &lastURLkey) as? NSURL
        }
    }
    
    private func kf_setWebURL(URL: NSURL) {
        objc_setAssociatedObject(self, &lastURLkey, URL, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
}

// MARK: - Deprecated
public extension UIImageView {
    @availability(*, deprecated=1.2, message="Use -kf_setImageWithURL:placeholderImage:optionsInfo: instead.")
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: [.Options: options], progressBlock: nil, completionHandler: nil)
    }
    
    @availability(*, deprecated=1.2, message="Use -kf_setImageWithURL:placeholderImage:optionsInfo:completionHandler: instead.")
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: [.Options: options], progressBlock: nil, completionHandler: completionHandler)
    }
    
    @availability(*, deprecated=1.2, message="Use -kf_setImageWithURL:placeholderImage:optionsInfo:progressBlock:completionHandler: instead.")
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions,
                         progressBlock: DownloadProgressBlock?,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: [.Options: options], progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
}

