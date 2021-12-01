//
//  TextAttachmentViewController.swift
//  Kingfisher
//
//  Created by onevcat on 2020/08/07.
//
//  Copyright (c) 2020 Wei Wang <onevcat@gmail.com>
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

import Kingfisher
import UIKit

class TextAttachmentViewController: UIViewController {
    @IBOutlet weak var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Text Attachment"
        setupOperationNavigationBar()

        loadAttributedText()
    }

    private func loadAttributedText() {
        let attributedText = NSMutableAttributedString(string: "Hello World")

        let textAttachment = NSTextAttachment()
        attributedText.replaceCharacters(in: NSRange(), with: NSAttributedString(attachment: textAttachment))
        label.attributedText = attributedText

        KF.url(URL(string: "https://onevcat.com/assets/images/avatar.jpg")!)
            .resizing(referenceSize: CGSize(width: 30, height: 30))
            .roundCorner(radius: .point(15))
            .set(to: textAttachment, attributedView: self.getLabel())
    }

    func getLabel() -> UILabel {
        return label
    }
}

extension TextAttachmentViewController: MainDataViewReloadable {
    func reload() {
        label.attributedText = NSAttributedString(string: "-")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadAttributedText()
        }
    }
}
