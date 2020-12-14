//
//  IndicatorCollectionViewController.swift
//  Kingfisher
//
//  Created by onevcat on 2018/11/26.
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

private let reuseIdentifier = "IndicatorCell"
let gifData: Data = {
    let url = Bundle.main.url(forResource: "loader", withExtension: "gif")!
    return try! Data(contentsOf: url)
}()

class IndicatorCollectionViewController: UICollectionViewController {

    class MyIndicator: Indicator {
        
        var timer: Timer?
        
        func startAnimatingView() {
            view.isHidden = false
            timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    if self.view.backgroundColor == .red {
                        self.view.backgroundColor = .orange
                    } else {
                        self.view.backgroundColor = .red
                    }
                })
            }
        }
        
        func stopAnimatingView() {
            view.isHidden = true
            timer?.invalidate()
        }
        
        var view: IndicatorView = {
            let view = UIView()
            view.heightAnchor.constraint(equalToConstant: 30).isActive = true
            view.widthAnchor.constraint(equalToConstant: 30).isActive = true
            
            view.backgroundColor = .red
            return view
        }()
    }
    
    let indicators: [String] = [
        "None",
        "UIActivityIndicatorView",
        "GIF Image",
        "Custom"
    ]
    var selectedIndicatorIndex: Int = 1 {
        didSet {
            collectionView.reloadData()
        }
    }
    var selectedIndicatorType: IndicatorType {
        switch selectedIndicatorIndex {
        case 0: return .none
        case 1: return .activity
        case 2: return .image(imageData: gifData)
        case 3: return .custom(indicator: MyIndicator())
        default: fatalError()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOperationNavigationBar()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ImageLoader.sampleImageURLs.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell
        cell.cellImageView.kf.indicatorType = selectedIndicatorType
        KF.url(ImageLoader.sampleImageURLs[indexPath.row])
            .memoryCacheExpiration(.expired)
            .diskCacheExpiration(.expired)
            .set(to: cell.cellImageView)
        return cell
    }
    
    override func alertPopup(_ sender: Any) -> UIAlertController {
        let alert = super.alertPopup(sender)
        for item in indicators.enumerated() {
            alert.addAction(UIAlertAction.init(title: item.element, style: .default) { _ in
                self.selectedIndicatorIndex = item.offset
            })
        }
        return alert
    }
}
