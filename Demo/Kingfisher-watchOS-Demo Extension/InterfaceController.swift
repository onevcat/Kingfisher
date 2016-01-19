//
//  InterfaceController.swift
//  Kingfisher-watchOS-Demo Extension
//
//  Created by Wei Wang on 16/1/19.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

import WatchKit
import Foundation
import Kingfisher

var count = 0

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var interfaceImage: WKInterfaceImage!
    
    var currentIndex: Int?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        currentIndex = count
        count++
    }
    
    func refreshImage() {
        let URL = NSURL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-\(currentIndex! + 1).jpg")!
        KingfisherManager.sharedManager.retrieveImageWithURL(URL, optionsInfo: nil, progressBlock: nil) { (image, error, cacheType, imageURL) -> () in
            self.interfaceImage.setImage(image)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        refreshImage()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
