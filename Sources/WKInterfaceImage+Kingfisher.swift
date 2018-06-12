//
//  WKInterfaceImage+Kingfisher.swift
//  Kingfisher
//
//  Created by Rodrigo Borges Soares on 04/05/18.
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

import WatchKit

// MARK: - Extension methods.
/**
 *    Set image to use from web.
 */
extension Kingfisher where Base: WKInterfaceImage {
    /**
     Set an image with a resource.

     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     */
    public func setImage(_ resource: Resource?) {
        guard let resource = resource else {
            return
        }

        KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil, completionHandler: { [weak base] image, error, cacheType, imageURL in
            DispatchQueue.main.safeAsync {
                base?.setImage(image)
            }
        })
    }
}

