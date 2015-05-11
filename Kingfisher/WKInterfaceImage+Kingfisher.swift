//
//  WKInterfaceImage+Kingfisher.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/5/1.
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

import WatchKit

public typealias WatchImageCompletionHandler = ((error: NSError?, cacheType: CacheType, imageURL: NSURL?, cachedInWatch: Bool) -> ())

public extension WKInterfaceImage {
    /**
    Set an image with a URL.
    
    It will ask for Kingfisher's manager to get the image for the URL.
    
    The device-side (Apple Watch) cache will be searched first by using the key of URL. If not found, Kingfisher will try to search it from iPhone/iPad memory and disk instead. If the manager does not find it yet, it will try to download the image at this URL and store it in iPhone/iPad for next use. You can use `KingfisherOptions.CacheInWatch` to store it in watch cache for better performance if you access this image often.
    
    :param: URL The URL of image.
    
    :returns: A task represents the retriving process or `nil` if device cache is used.
    */
    public func kf_setImageWithURL(URL: NSURL) -> RetrieveImageTask?
    {
        return kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a URL and a placeholder image.
    
    It will ask for Kingfisher's manager to get the image for the URL.
    
    The device-side (Apple Watch) cache will be searched first by using the key of URL. If not found, Kingfisher will try to search it from iPhone/iPad memory and disk instead. If the manager does not find it yet, it will try to download the image at this URL and store it in iPhone/iPad for next use. You can use `KingfisherOptions.CacheInWatch` to store it in watch cache for better performance if you access this image often.
    
    :param: URL              The URL of image.
    :param: placeholderImage A placeholder image when retrieving the image at URL.
    
    :returns: A task represents the retriving process.
    */
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?) -> RetrieveImageTask?
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a URL and a named image resource file as placeholder.
    
    :param: URL  The URL of image.
    :param: name The name of an image in WatchKit app bundle or the device-side cache.
    
    :returns: A task represents the retriving process or `nil` if device cache is used.
    */
    public func kf_setImageWithURL(URL: NSURL,
            placeholderImageNamed name: String?) -> RetrieveImageTask?
    {
        return kf_setImageWithURL(URL, placeholderImageNamed: name, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a URL, a placaholder image and options.
    
    :param: URL              The URL of image.
    :param: placeholderImage A placeholder image when retrieving the image at URL.
    :param: optionsInfo      A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    
    :returns: A task represents the retriving process or `nil` if device cache is used.
    */
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?) -> RetrieveImageTask?
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a URL and a named image resource file as placeholder and options.
    
    :param: URL         The URL of image.
    :param: name        The name of an image in WatchKit app bundle or the device-side cache.
    :param: optionsInfo A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    
    :returns: A task represents the retriving process or `nil` if device cache is used.
    */
    public func kf_setImageWithURL(URL: NSURL,
            placeholderImageNamed name: String?,
                           optionsInfo: KingfisherOptionsInfo?) -> RetrieveImageTask?
    {
        return kf_setImageWithURL(URL, placeholderImageNamed: name, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: nil)
    }
    
    /**
    Set an image with a URL, a placeholder image, options and completion handler.
    
    :param: URL               The URL of image.
    :param: placeholderImage  A placeholder image when retrieving the image at URL.
    :param: optionsInfo       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    :param: completionHandler Called when the image retrieved and set.
    
    :returns: A task represents the retriving process or `nil` if device cache is used.
    */
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?,
                     completionHandler: WatchImageCompletionHandler?) -> RetrieveImageTask?
    {
        return kf_setImageWithURL(URL, placeholderImage: placeholderImage, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: completionHandler)
    }
    
    /**
    Set an image with a URL and a named image resource file as placeholder, options and completion handler.
    
    :param: URL               The URL of image.
    :param: name              The name of an image in WatchKit app bundle or the device-side cache.
    :param: optionsInfo       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    :param: completionHandler Called when the image retrieved and set.
    
    :returns: A task represents the retriving process or `nil` if device cache is used.
    */
    public func kf_setImageWithURL(URL: NSURL,
            placeholderImageNamed name: String?,
                           optionsInfo: KingfisherOptionsInfo?,
                     completionHandler: WatchImageCompletionHandler?) -> RetrieveImageTask?
    {
        return kf_setImageWithURL(URL, placeholderImageNamed: name, optionsInfo: optionsInfo, progressBlock: nil, completionHandler: completionHandler)
    }
    
    /**
    Set an image with a URL, a placeholder image, options, progress handler and completion handler.
    
    :param: URL               The URL of image.
    :param: placeholderImage  A placeholder image when retrieving the image at URL.
    :param: optionsInfo       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    :param: progressBlock     Called when the image downloading progress gets updated.
    :param: completionHandler Called when the image retrieved and set.
    
    :returns: A task represents the retriving process or `nil` if device cache is used.
    */
    public func kf_setImageWithURL(URL: NSURL,
                      placeholderImage: UIImage?,
                           optionsInfo: KingfisherOptionsInfo?,
                         progressBlock: DownloadProgressBlock?,
                     completionHandler: WatchImageCompletionHandler?) -> RetrieveImageTask?
    {
        let preSet = kf_prepareImageURL(URL, optionsInfo: optionsInfo, completionHandler: completionHandler)
        
        if preSet.set {
            return nil
        } else {
            setImage(placeholderImage)
            return kf_retrieveImageWithURL(URL, optionsInfo: optionsInfo, cacheInWatch: preSet.cacheInWatch, progressBlock: progressBlock, completionHandler: completionHandler)
        }
    }
    
    /**
    Set an image with a URL and a named image resource file as placeholder, options progress handler and completion handler.
    
    :param: URL               The URL of image.
    :param: name              The name of an image in WatchKit app bundle or the device-side cache.
    :param: optionsInfo       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
    :param: progressBlock     Called when the image downloading progress gets updated.
    :param: completionHandler Called when the image retrieved and set.
    
    :returns: A task represents the retriving process or `nil` if device cache is used.
    */
    public func kf_setImageWithURL(URL: NSURL,
            placeholderImageNamed name: String?,
                           optionsInfo: KingfisherOptionsInfo?,
                         progressBlock: DownloadProgressBlock?,
                     completionHandler: WatchImageCompletionHandler?) -> RetrieveImageTask?
    {
        let preSet = kf_prepareImageURL(URL, optionsInfo: optionsInfo, completionHandler: completionHandler)
        
        if preSet.set {
            return nil
        } else {
            setImageNamed(name)
            return kf_retrieveImageWithURL(URL, optionsInfo: optionsInfo, cacheInWatch: preSet.cacheInWatch, progressBlock: progressBlock, completionHandler: completionHandler)
        }
    }
    
    /**
    Get the hash for a URL in Watch side cache.
    
    You can use the returned string to check whether the corresponding image is cached in watch or not, by using `WKInterfaceDevice.currentDevice().cachedImages`
    
    :param: string The absolute string of a URL.
    
    :returns: The hash string used when cached in Watch side cache.
    */
    public class func kf_cacheKeyForURLString(string: String) -> String {
        return string.kf_MD5()
    }
}

// MARK: - Private methods
extension WKInterfaceImage {
    private func kf_prepareImageURL(URL: NSURL,
        optionsInfo: KingfisherOptionsInfo?,
        completionHandler: WatchImageCompletionHandler?) -> (set: Bool, cacheInWatch: Bool)
    {
        
        kf_setWebURL(URL)
        
        let cacheInWatch: Bool
        let forceRefresh: Bool
        
        if let options = optionsInfo?[.Options] as? KingfisherOptions {
            cacheInWatch = ((options & KingfisherOptions.CacheInWatch) != KingfisherOptions.None)
            forceRefresh = ((options & KingfisherOptions.ForceRefresh) != KingfisherOptions.None)
        } else {
            cacheInWatch = false
            forceRefresh = false
        }
        
        let imageKey: String
        if let URLString = URL.absoluteString {
            imageKey = WKInterfaceImage.kf_cacheKeyForURLString(URLString)
        } else {
            return (false, cacheInWatch)
        }
        
        if forceRefresh {
            WKInterfaceDevice.currentDevice().removeCachedImageWithName(imageKey)
        }
        
        if WKInterfaceDevice.currentDevice().cachedImages[imageKey] != nil {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.setImageNamed(imageKey)
                completionHandler?(error: nil, cacheType: .Watch, imageURL: URL, cachedInWatch: true)
            })
            
            return (true, cacheInWatch)
        }
        
        return (false, cacheInWatch)
    }
    
    private func kf_retrieveImageWithURL(URL: NSURL,
        optionsInfo: KingfisherOptionsInfo?,
        cacheInWatch: Bool,
        progressBlock: DownloadProgressBlock?,
        completionHandler: WatchImageCompletionHandler?) -> RetrieveImageTask?
    {
        let task = KingfisherManager.sharedManager.retrieveImageWithURL(URL, optionsInfo: optionsInfo, progressBlock: { (receivedSize, totalSize) -> () in
            if let progressBlock = progressBlock {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    progressBlock(receivedSize: receivedSize, totalSize: totalSize)
                })
            }
            }) { (image, error, cacheType, imageURL) -> () in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    var cachedInWatch: Bool = false
                    
                    if (imageURL == self.kf_webURL && image != nil) {
                        self.setImage(image)
                        
                        if cacheInWatch {
                            if let URLString = URL.absoluteString {
                                let key = WKInterfaceImage.kf_cacheKeyForURLString(URLString)
                                cachedInWatch = WKInterfaceDevice.currentDevice().addCachedImage(image!, name: key)
                            }
                        }
                    }
                    
                    completionHandler?(error: error, cacheType: cacheType, imageURL: imageURL, cachedInWatch: cachedInWatch)
                })
        }
        
        return task
    }
}


// MARK: - Associated Object
private var lastURLkey: Void?
public extension WKInterfaceImage {
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