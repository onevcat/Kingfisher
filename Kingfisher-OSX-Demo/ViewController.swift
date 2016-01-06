//
//  ViewController.swift
//  Kingfisher-OSX-Demo
//
//  Created by WANG WEI on 2016/01/06.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

import AppKit

class ViewController: NSViewController {

    
    @IBOutlet weak var imageView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        imageView.imageScaling = .ScaleNone
        imageView.animates = true
        
        let image = NSImage(named: "dancing-banana.gif")
        
        let ddd = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("dancing-banana", ofType: "gif")!)!
        
        let rep = image!.representations.first as! NSBitmapImageRep
        print(rep.valueForProperty(NSImageFrameCount))
        let data = rep.representationUsingType(.NSGIFFileType, properties: [:])!
        imageView.image = NSImage(data: data)
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}
