//
//  InterfaceController.swift
//  Kingfisher-watchOS-Demo Extension
//
//  Created by Wei Wang on 16/1/19.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
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

var count = 0

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var interfaceImage: WKInterfaceImage!
    
    var currentIndex: Int?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        currentIndex = count
        count += 1
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
