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

import UIKit

// MARK: - Set Images
/**
*	Set image to use from web.
*/

public extension UIImageView {
    
    /**
    Set an image with a resource.
    It will ask for Kingfisher's manager to get the image for the `cacheKey` property in `resource`.
    The memory and disk will be searched first. If the manager does not find it, it will try to download the image at the `resource.downloadURL` and store it with `resource.cacheKey` for next use.
    
    - parameter resource: Resource object contains information such as `cacheKey` and `downloadURL`.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithResource(resource: Resource) -> RetrieveImageTask
    {
        return kf_setImageWithResource(resource, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a URL.
    It will ask for Kingfisher's manager to get the image for the URL.
    The memory and disk will be searched first with `URL.absoluteString` as the cache key. If the manager does not find it, it will try to download the image at this URL and store the image with `URL.absoluteString` as cache key for next use.
    
    If you need to specify the key other than `URL.absoluteString`, please use resource version of these APIs with `resource.cacheKey` set to what you want.
    
    - parameter URL: The URL of image.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithURL(URL: NSURL) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }

    /**
    Set an image with a resource and a placeholder image.
    
    - parameter resource:         Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithResource(resource: Resource,
                                placeholderImage: UIImage?) -> RetrieveImageTask
    {
        return kf_setImageWithResource(resource, placeholderImage: placeholderImage, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a URL and a placeholder image.
    
    - parameter URL:              The URL of image.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a resource, a placaholder image and options.
    
    - parameter resource:         Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:      A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithResource(resource: Resource,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?) -> RetrieveImageTask
    {
        return kf_setImageWithResource(resource, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a URL, a placaholder image and options.
    
    - parameter URL:              The URL of image.
    - parameter placeholderImage: A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:      A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a resource, a placeholder image, options and completion handler.
    
    - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithResource(resource: Resource,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithResource(resource, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: completionHandler)
    }
    
    /**
    Set an image with a URL, a placeholder image, options and completion handler.
    
    - parameter URL:               The URL of image.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
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
    
    - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter progressBlock:     Called when the image downloading progress gets updated.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
    */
    public func kf_setImageWithResource(resource: Resource,
                                placeholderImage: UIImage?,
                                     optionsInfo: KingfisherOptionsInfo?,
                                   progressBlock: DownloadProgressBlock?,
                               completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        let showIndicatorWhenLoading = kf_showIndicatorWhenLoading
        var indicator: UIActivityIndicatorView? = nil
        if showIndicatorWhenLoading {
            indicator = kf_indicator
            indicator?.hidden = false
            indicator?.startAnimating()
        }
        
        image = placeholderImage
        
        kf_setWebURL(resource.downloadURL)
        let task = KingfisherManager.sharedManager.retrieveImageWithResource(resource, optionsInfo: optionsInfo,
            progressBlock: { receivedSize, totalSize in
                if let progressBlock = progressBlock {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                        
                    })
                }
            },
            completionHandler: {[weak self] image, error, cacheType, imageURL in
                
                dispatch_async_safely_main_queue {
                    if let sSelf = self where imageURL == sSelf.kf_webURL && image != nil {
                        
                        if let transitionItem = optionsInfo?.kf_findFirstMatch(.Transition(.None)),
                            case .Transition(let transition) = transitionItem where cacheType == .None {
                            
                            UIView.transitionWithView(sSelf, duration: 0.0, options: [],
                                animations: {
                                    indicator?.stopAnimating()
                                },
                                completion: { finished in
                                    UIView.transitionWithView(sSelf, duration: transition.duration,
                                        options: transition.animationOptions,
                                        animations: {
                                            transition.animations?(sSelf, image!)
                                        },
                                        completion: { finished in
                                            transition.completion?(finished)
                                            completionHandler?(image: image, error: error, cacheType: cacheType, imageURL: imageURL)
                                        }
                                    )
                                }
                            )
                        } else {
                            indicator?.stopAnimating()
                            sSelf.image = image;
                            completionHandler?(image: image, error: error, cacheType: cacheType, imageURL: imageURL)
                        }
                    } else {
                        completionHandler?(image: image, error: error, cacheType: cacheType, imageURL: imageURL)
                    }
                }
            }
        )
        
        return task
    }
    
    /**
    Set an image with a URL, a placeholder image, options, progress handler and completion handler.
    
    - parameter URL:               The URL of image.
    - parameter placeholderImage:  A placeholder image when retrieving the image at URL.
    - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    - parameter progressBlock:     Called when the image downloading progress gets updated.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
    */
    
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?,
                         progressBlock: DownloadProgressBlock?,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithResource(Resource(downloadURL: URL),
                            placeholderImage: placeholderImage,
                                 optionsInfo: optionsInfo,
                               progressBlock: progressBlock,
                           completionHandler: completionHandler)
    }
}

// MARK: - Associated Object
private var lastURLKey: Void?
private var indicatorKey: Void?
private var showIndicatorWhenLoadingKey: Void?

public extension UIImageView {
    /// Get the image URL binded to this image view.
    public var kf_webURL: NSURL? {
        return objc_getAssociatedObject(self, &lastURLKey) as? NSURL
    }
    
    private func kf_setWebURL(URL: NSURL) {
        objc_setAssociatedObject(self, &lastURLKey, URL, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// Whether show an animating indicator when the image view is loading an image or not.
    /// Default is false.
    public var kf_showIndicatorWhenLoading: Bool {
        get {
            if let result = objc_getAssociatedObject(self, &showIndicatorWhenLoadingKey) as? NSNumber {
                return result.boolValue
            } else {
                return false
            }
        }
        
        set {
            if kf_showIndicatorWhenLoading == newValue {
                return
            } else {
                if newValue {
                    #if os(tvOS)
                        let indicatorStyle = UIActivityIndicatorViewStyle.White
                    #else
                        let indicatorStyle = UIActivityIndicatorViewStyle.Gray
                    #endif
                    let indicator = UIActivityIndicatorView(activityIndicatorStyle:indicatorStyle)
                    indicator.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
                    
                    indicator.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleTopMargin]
                    indicator.hidden = true
                    indicator.hidesWhenStopped = true
                    
                    self.addSubview(indicator)
                    
                    kf_setIndicator(indicator)
                } else {
                    kf_indicator?.removeFromSuperview()
                    kf_setIndicator(nil)
                }
                
                objc_setAssociatedObject(self, &showIndicatorWhenLoadingKey, NSNumber(bool: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    /// The indicator view showing when loading. This will be `nil` if `kf_showIndicatorWhenLoading` is false.
    /// You may want to use this to set the indicator style or color when you set `kf_showIndicatorWhenLoading` to true.
    public var kf_indicator: UIActivityIndicatorView? {
        return objc_getAssociatedObject(self, &indicatorKey) as? UIActivityIndicatorView
    }
    
    private func kf_setIndicator(indicator: UIActivityIndicatorView?) {
        objc_setAssociatedObject(self, &indicatorKey, indicator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - Deprecated
public extension UIImageView {
    @available(*, deprecated=1.2, message="Use -kf_setImageWithURL:placeholderImage:optionsInfo: instead.")
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: [.Options(options)], progressBlock: nil, completionHandler: nil)
    }
    
    @available(*, deprecated=1.2, message="Use -kf_setImageWithURL:placeholderImage:optionsInfo:completionHandler: instead.")
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: [.Options(options)], progressBlock: nil, completionHandler: completionHandler)
    }
    
    @available(*, deprecated=1.2, message="Use -kf_setImageWithURL:placeholderImage:optionsInfo:progressBlock:completionHandler: instead.")
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                               options: KingfisherOptions,
                         progressBlock: DownloadProgressBlock?,
                     completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: [.Options(options)], progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
}
