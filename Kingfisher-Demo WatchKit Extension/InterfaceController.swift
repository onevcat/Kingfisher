//
//  InterfaceController.swift
//  Kingfisher-Demo WatchKit Extension
//
//  Created by Wei Wang on 15/5/1.
//
//  Copyright (c) 2015 Wei Wang <onevcat@gmail.com>
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
        
        imageView.kf_setImageWithURL(NSURL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-\(InterfaceController.counter).jpg")!, placeholderImage: nil, optionsInfo: [.Options: KingfisherOptions.CacheInWatch], progressBlock: { (receivedSize, totalSize) -> () in
            
        }) { (error, cacheType, imageURL, cachedInWatch) -> () in
            println("\(imageURL) : \(cachedInWatch)")
        }
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
