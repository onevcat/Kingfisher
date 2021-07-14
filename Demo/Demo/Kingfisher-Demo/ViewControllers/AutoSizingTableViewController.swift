//
//  AutoSizingTableViewController.swift
//  Kingfisher
//
//  Created by onevcat on 2021/03/15.
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

// Cell with an image view (loading by Kingfisher) with fix width and dynamic height which keeps the image with aspect ratio.
class AutoSizingTableViewCell: UITableViewCell {
    
    static let p = ResizingImageProcessor(referenceSize: .init(width: 200, height: CGFloat.infinity), mode: .aspectFit)
    
    @IBOutlet weak var leadingImageView: UIImageView!
    @IBOutlet weak var sizeLabel: UILabel!
    
    var updateLayout: (() -> Void)?
    
    func set(with url: URL) {
        leadingImageView.kf.setImage(with: url, options: [.processor(AutoSizingTableViewCell.p), .transition(.fade(1))]) { r in
            if case .success(let value) = r {
                self.sizeLabel.text = "\(value.image.size.width) x \(value.image.size.height)"
                self.updateLayout?()
            } else {
                self.sizeLabel.text = ""
            }
        }
    }
}

class AutoSizingTableViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var data: [Int] = Array(1..<700)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 150
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.setAnimationsEnabled(false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.setAnimationsEnabled(true)
    }
}

extension AutoSizingTableViewController: UITableViewDataSource {
    private func updateLayout() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AutoSizingTableViewCell", for: indexPath) as! AutoSizingTableViewCell
        cell.set(with: ImageLoader.roseImage(index: data[indexPath.row]))
        cell.updateLayout = { [weak self] in
            self?.updateLayout()
        }
        return cell
    }
    
    
}
