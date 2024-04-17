//
//  PHPickerResultViewController.swift
//  Kingfisher
//
//  Created by nuomi1 on 2024-04-17.
//
//  Copyright (c) 2024 Wei Wang <onevcat@gmail.com>
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

import Foundation
import Kingfisher
import PhotosUI
import UIKit

class PHPickerResultViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!

    @IBAction func onTapButton() {
        if #available(iOS 14.0, *) {
            presentPickerViewController()
        } else {
            presentAlertController()
        }
    }

    private func presentAlertController() {
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let alertController = UIAlertController(title: "Warning!", message: "Only supports iOS 14+", preferredStyle: .alert)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    @available(iOS 14.0, *)
    private func presentPickerViewController() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let viewController = PHPickerViewController(configuration: configuration)
        viewController.delegate = self
        present(viewController, animated: true)
    }
}

@available(iOS 14, *)
extension PHPickerResultViewController: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        let provider = PHPickerResultImageDataProvider(pickerResult: result)
        imageView.kf.setImage(with: .provider(provider))
    }
}
