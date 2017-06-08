//
//  ViewController.swift
//  Kingfisher-macOS-Demo
//
//  Created by Wei Wang on 16/1/6.
//
//  Copyright (c) 2017 Wei Wang <onevcat@gmail.com>
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

import AppKit
import Kingfisher

class ViewController: NSViewController {
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Kingfisher"
    }

    @IBAction func clearCachePressed(sender: AnyObject) {
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache()
    }
    
    @IBAction func reloadPressed(sender: AnyObject) {
        collectionView.reloadData()
    }
}

extension ViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Cell"), for: indexPath)
        
        let url = URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-\(indexPath.item + 1).jpg")!
        
        item.imageView?.kf.indicatorType = .activity
        item.imageView?.kf.setImage(with: url, placeholder: nil, options: nil,
                                                   progressBlock: { receivedSize, totalSize in
                                                    print("\(indexPath.item + 1): \(receivedSize)/\(totalSize)")
                                                    },
                                              completionHandler: { image, error, cacheType, imageURL in
                                                    print("\(indexPath.item + 1): Finished")
                                                    })
        
        // Set imageView's `animates` to true if you are loading a GIF.
        // item.imageView?.animates = true
        return item
    }
}
