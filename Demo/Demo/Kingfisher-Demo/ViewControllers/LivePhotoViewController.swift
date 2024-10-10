//
//  LivePhotoViewController.swift
//  Kingfisher
//
//  Created by onevcat on 2024/10/05.
//
//  Copyright (c) 2024 Wei Wang <onevcat@gmail.com>
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
import PhotosUI
import Kingfisher

class LivePhotoViewController: UIViewController {
    
    private var livePhotoView: PHLivePhotoView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Live Photo"
        setupOperationNavigationBar()
        
        livePhotoView = PHLivePhotoView()
        livePhotoView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(livePhotoView)
        NSLayoutConstraint.activate([
            livePhotoView.heightAnchor.constraint(equalToConstant: 300),
            livePhotoView.widthAnchor.constraint(equalToConstant: 300),
            livePhotoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            livePhotoView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30)
        ])
        
        let urls = [
            "https://github.com/onevcat/Kingfisher-TestImages/raw/refs/heads/master/LivePhotos/live_photo_sample.HEIC",
            "https://github.com/onevcat/Kingfisher-TestImages/raw/refs/heads/master/LivePhotos/live_photo_sample.MOV"
        ].compactMap(URL.init)
        livePhotoView.kf.setImage(with: urls, completionHandler: { result in
            switch result {
            case .success(let r):
                print("Live Photo done. \(r.loadingInfo.cacheType)")
                print("Info: \(String(describing: r.info))")
            case .failure(let error):
                print("Live Photo error: \(error)")
            }
        })
    }
}
