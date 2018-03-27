//
//  BackgroundImageFetch.swift
//  TourBook
//
//  Created by Nadia Yudina on 3/27/18.
//  Copyright © 2018 The Square Foot. All rights reserved.
//

import UIKit

public class BackgroundImageFetch {

    private var urls: [URL] = []

    public convenience init(urls: [URL]) {
        self.init()
        self.urls = urls
    }

    public func fetch() {
        DispatchQueue.global(qos: .background).async {
            let manager = KingfisherManager.shared
            for imageUrl in self.urls {
                if manager.cache.imageCachedType(forKey: imageUrl.absoluteString) == .none {
                    URLSession.shared.dataTask(with: imageUrl, completionHandler: { (data, _, _) in
                        if let data = data, let image = UIImage(data: data) {
                            if manager.cache.imageCachedType(forKey: imageUrl.absoluteString) == .none {
                                manager.cache.store(image, forKey: imageUrl.absoluteString)
                            }
                        }
                    }).resume()
                }
            }
        }
    }

    
}
