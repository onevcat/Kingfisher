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
    private var isWait = true
    private var isFastestScan = true
    
    private let url = URL(string: "https://demo-resources.oss-cn-beijing.aliyuncs.com/progressive.jpg")!
//    private let url = URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher-9.jpg")!
    private let processor = RoundCornerImageProcessor(cornerRadius: 30)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Progressive JPEG"
        setupOperationNavigationBar()
        loadImage()
    }
    
    private func loadImage() {
        progressLabel.text = "- / -"
        
        let progressive = ImageProgressive(
            isBlur: isBlur,
            isWait: isWait,
            isFastestScan: isFastestScan,
            scanInterval: 0.1
        )
        
        imageView.kf.setImage(
            with: url,
            placeholder: nil,
            options: [.loadDiskFileSynchronously,
                      .progressiveJPEG(progressive),
                      .processor(processor)],
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
        
        func reloadImage() {
            // Cancel
            imageView.kf.cancelDownloadTask()
            // Clean cache
            KingfisherManager.shared.cache.removeImage(
                forKey: self.url.cacheKey,
                processorIdentifier: self.processor.identifier,
                callbackQueue: .mainAsync,
                completionHandler: {
                    self.loadImage()
                }
            )
        }
        
        do {
            let title = isBlur ? "Close Blur" : "Enabled Blur"
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.isBlur.toggle()
                reloadImage()
            })
        }
        
        do {
            let title = isWait ? "Close Wait" : "Enabled Wait"
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.isWait.toggle()
                reloadImage()
            })
        }
        
        do {
            let title = isFastestScan ? "Close Fastest Scan" : "Enabled Fastest Scan"
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.isFastestScan.toggle()
                reloadImage()
            })
        }
        return alert
    }
}
