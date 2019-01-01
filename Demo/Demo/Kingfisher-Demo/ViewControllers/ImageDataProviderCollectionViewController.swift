//
//  ImageDataProviderCollectionViewController.swift
//  Kingfisher
//
//  Created by onevcat on 2018/12/08.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
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

import UIKit
import Kingfisher

private let reuseIdentifier = "ImageDataProviderCell"

class ImageDataProviderCollectionViewController: UICollectionViewController {

    let model: [(String, UIColor)] = [
        ("A", .red), ("B", .green), ("C", .blue), ("D", .yellow), ("赵", .purple), ("钱", .orange),
        ("孙", .black), ("李", .brown), ("ア", .darkGray), ("イ", .cyan), ("ウ", .magenta)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Provider"
        setupOperationNavigationBar()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell
    
        let pair = model[indexPath.row]
        let provider = UserNameLetterIconImageProvider(userNameFirstLetter: pair.0, backgroundColor: pair.1)
        cell.cellImageView.kf.setImage(with: provider, options:[.processor(RoundCornerImageProcessor(cornerRadius: 75))])

        return cell
    }
}

struct UserNameLetterIconImageProvider: ImageDataProvider {
    var cacheKey: String { return letter }
    let letter: String
    let color: UIColor
    
    init(userNameFirstLetter: String, backgroundColor: UIColor) {
        letter = userNameFirstLetter
        color = backgroundColor
    }
    
    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        let letter = self.letter as NSString
        let rect = CGRect(x: 0, y: 0, width: 250, height: 250)
        
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
        let data = renderer.pngData { context in
            color.setFill()
            context.fill(rect)
            
            let attributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 200)
            ]
            
            let textSize = letter.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height)
            letter.draw(in: textRect, withAttributes: attributes)
        }
        handler(.success(data))
    }
}
