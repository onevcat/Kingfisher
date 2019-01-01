//
//  GIFViewController.swift
//  Kingfisher
//
//  Created by onevcat on 2018/11/25.
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

import UIKit
import Kingfisher

class GIFViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var animatedImageView: AnimatedImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = ImageLoader.gifImageURLs.last!
        
        // Should need to use different cache key to prevent data overwritten by each other.
        
        let imageViewResource = ImageResource(downloadURL: url, cacheKey: "\(url)-imageview")
        imageView.kf.setImage(with: imageViewResource)
        
        let animatedImageViewResource = ImageResource(downloadURL: url, cacheKey: "\(url)-animated_imageview")
        animatedImageView.kf.setImage(with: animatedImageViewResource)
    }
}
