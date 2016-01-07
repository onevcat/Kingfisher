//
//  ViewController.swift
//  Kingfisher-OSX-Demo
//
//  Created by WANG WEI on 2016/01/06.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

import AppKit
import Kingfisher

class ViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Kingfisher"
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

extension ViewController: NSCollectionViewDataSource {
    func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItemWithIdentifier("Cell", forIndexPath: indexPath)
        
        let URL = NSURL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-\(indexPath.item + 1).jpg")!
        
        item.imageView?.kf_showIndicatorWhenLoading = true
        item.imageView?.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: nil,
                                                   progressBlock: { receivedSize, totalSize in
                                                    print("\(indexPath.item + 1): \(receivedSize)/\(totalSize)")
                                                    },
                                              completionHandler: { image, error, cacheType, imageURL in
                                                    print("\(indexPath.item + 1): Finished")
                                                    }
        )
        
        return item
    }
}