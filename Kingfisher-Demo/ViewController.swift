//
//  ViewController.swift
//  Kingfisher-Demo
//
//  Created by Wei Wang on 15/4/6.
//  Copyright (c) 2015年 Wei Wang. All rights reserved.
//

import UIKit
import Kingfisher

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imageView.kf_setImageWithURL(NSURL(string: "http://onevcat.com/content/images/2014/May/200.jpg")!, placeHolderImage: nil, options: KingfisherOptions.LowPriority | KingfisherOptions.BackgroundDecode)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

