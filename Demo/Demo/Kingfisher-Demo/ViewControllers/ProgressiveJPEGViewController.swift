//
//  ProgressiveJPEGViewController.swift
//  Kingfisher
//
//  Created by lixiang on 2019/5/12.
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

class ProgressiveJPEGViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressLabel: UILabel!
    
    private var isBlur = true
    private let url = URL(string: "https://demo-resources.oss-cn-beijing.aliyuncs.com/progressive.jpg")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Progressive JPEG"
        setupOperationNavigationBar()
        loadImage()
    }
    
    private func loadImage() {
        progressLabel.text = "- / -"
        
        imageView.kf.setImage(
            with: url,
            placeholder: nil,
            options: [.loadDiskFileSynchronously, .progressiveJPEG(isBlur)],
            progressBlock: { receivedSize, totalSize in
                print("\(receivedSize)/\(totalSize)")
                self.progressLabel.text = "\(receivedSize) / \(totalSize)"
            },
            completionHandler: { result in
                print(result)
                print("Finished")
            }
        )
    }
    
    override func alertPopup(_ sender: Any) -> UIAlertController {
        let alert = super.alertPopup(sender)
        let title = isBlur ? "Close Blur" : "Enabled Blur"
        alert.addAction(UIAlertAction(title: title, style: .default) { _ in
            self.isBlur.toggle()
            // Clean cache
            KingfisherManager.shared.cache.removeImage(
                forKey: self.url.cacheKey,
                callbackQueue: .mainAsync,
                completionHandler: {
                    self.loadImage()
                }
            )
        })
        return alert
    }
}
