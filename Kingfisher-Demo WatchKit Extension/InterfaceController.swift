//
//  InterfaceController.swift
//  Kingfisher-Demo WatchKit Extension
//
//  Created by WANG WEI on 2015/05/01.
//  Copyright (c) 2015年 Wei Wang. All rights reserved.
//

import WatchKit
import Foundation
import Kingfisher

class InterfaceController: WKInterfaceController {

    @IBOutlet weak var imageView: WKInterfaceImage!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        imageView.kf_setImageWithURL(NSURL(string: "http://onevcat.com/content/images/2014/May/200.jpg")!)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
