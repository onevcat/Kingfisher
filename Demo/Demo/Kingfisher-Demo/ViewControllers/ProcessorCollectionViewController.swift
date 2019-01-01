//
//  ProcessorCollectionViewController.swift
//  Kingfisher
//
//  Created by onevcat on 2018/11/19.
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

private let reuseIdentifier = "ProcessorCell"

class ProcessorCollectionViewController: UICollectionViewController {

    var currentProcessor: ImageProcessor = DefaultImageProcessor.default {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var processors: [(ImageProcessor, String)] = [
        (DefaultImageProcessor.default, "Default"),
        (RoundCornerImageProcessor(cornerRadius: 20), "Round Corner"),
        (RoundCornerImageProcessor(cornerRadius: 20, roundingCorners: [.topLeft, .bottomRight]), "Round Corner Partial"),
        (BlendImageProcessor(blendMode: .lighten, alpha: 1.0, backgroundColor: .red), "Blend"),
        (BlurImageProcessor(blurRadius: 5), "Blur"),
        (OverlayImageProcessor(overlay: .red, fraction: 0.5), "Overlay"),
        (TintImageProcessor(tint: UIColor.red.withAlphaComponent(0.5)), "Tint"),
        (ColorControlsProcessor(brightness: 0.0, contrast: 1.1, saturation: 1.1, inputEV: 1.0), "Vibrancy"),
        (BlackWhiteProcessor(), "B&W"),
        (CroppingImageProcessor(size: CGSize(width: 100, height: 100)), "Cropping"),
        (DownsamplingImageProcessor(size: CGSize(width: 25, height: 25)), "Downsampling"),
        (BlurImageProcessor(blurRadius: 5) >> RoundCornerImageProcessor(cornerRadius: 20), "Blur + Round Corner")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Processor"
        setupOperationNavigationBar()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ImageLoader.sampleImageURLs.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell
        let url = ImageLoader.sampleImageURLs[indexPath.row]
        var options: KingfisherOptionsInfo = [.processor(currentProcessor)]
        if currentProcessor is RoundCornerImageProcessor {
            options.append(.cacheSerializer(FormatIndicatedCacheSerializer.png))
        }
        cell.cellImageView.kf.setImage(with: url, options: options) { result in
            print(result)
        }
        return cell
    }
    
    override func alertPopup(_ sender: Any) -> UIAlertController {
        let alert = super.alertPopup(sender)
        alert.addAction(UIAlertAction(title: "Processor", style: .default, handler: { _ in
            let alert = UIAlertController(title: "Processor", message: nil, preferredStyle: .actionSheet)
            for item in self.processors {
                alert.addAction(UIAlertAction(title: item.1, style: .default) { _ in self.currentProcessor = item.0 })
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            self.present(alert, animated: true)
        }))
        return alert
    }
}
