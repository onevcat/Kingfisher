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

    static var counter: Int = 0
    
    @IBOutlet weak var imageView: WKInterfaceImage!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        // Configure interface objects here.
        InterfaceController.counter =  InterfaceController.counter + 1
        imageView.kf_setImageWithURL(NSURL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-\(InterfaceController.counter).jpg")!)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
