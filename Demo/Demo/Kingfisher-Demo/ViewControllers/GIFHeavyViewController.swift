//
//  GIFHeavyViewController.swift
//  Kingfisher
//
//  Created by taras on 16/04/2021.
//
//  Copyright (c) 2021 Wei Wang <onevcat@gmail.com>
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

class GIFHeavyViewController: UIViewController {
    let stackView = UIStackView()
    let imageView_1 = AnimatedImageView()
    let imageView_2 = AnimatedImageView()
    let imageView_3 = AnimatedImageView()
    let imageView_4 = AnimatedImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                stackView.topAnchor.constraint(equalTo: view.topAnchor),
                stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
        
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        
        stackView.addArrangedSubview(imageView_1)
        stackView.addArrangedSubview(imageView_2)
        stackView.addArrangedSubview(imageView_3)
        stackView.addArrangedSubview(imageView_4)
        
        imageView_1.contentMode = .scaleAspectFit
        imageView_2.contentMode = .scaleAspectFit
        imageView_3.contentMode = .scaleAspectFit
        imageView_4.contentMode = .scaleAspectFit
        
        let url = URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/GIF/GifHeavy.gif")

        imageView_1.kf.setImage(with: url)
        imageView_2.kf.setImage(with: url)
        imageView_3.kf.setImage(with: url)
        imageView_4.kf.setImage(with: url)
    }
}
