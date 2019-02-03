//
//  UIViewController+KingfisherOperation.swift
//  Kingfisher
//
//  Created by onevcat on 2018/11/18.
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

protocol MainDataViewReloadable {
    func reload()
}

extension UITableViewController: MainDataViewReloadable {
    func reload() {
        tableView.reloadData()
    }
}

extension UICollectionViewController: MainDataViewReloadable {
    func reload() {
        collectionView.reloadData()
    }
}

protocol KingfisherActionAlertPopup {
    func alertPopup(_ sender: Any) -> UIAlertController
}

func cleanCacheAction() -> UIAlertAction {
    return UIAlertAction(title: "Clean Cache", style: .default) { _ in
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache()
    }
}

func reloadAction(_ reloadable: MainDataViewReloadable) -> UIAlertAction {
    return UIAlertAction(title: "Reload", style: .default) { _ in
        reloadable.reload()
    }
}

let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

func createAlert(_ sender: Any, actions: [UIAlertAction]) -> UIAlertController {
    let alert = UIAlertController(title: "Action", message: nil, preferredStyle: .actionSheet)
    alert.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
    alert.popoverPresentationController?.permittedArrowDirections = .any
    
    actions.forEach { alert.addAction($0) }
    
    return alert
}

extension UIViewController: KingfisherActionAlertPopup {
    @objc func alertPopup(_ sender: Any) -> UIAlertController {
        let alert = createAlert(sender, actions: [cleanCacheAction(), cancelAction])
        if let r = self as? MainDataViewReloadable {
            alert.addAction(reloadAction(r))
        }
        return alert
    }
}

extension UIViewController  {
    func setupOperationNavigationBar() {
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "Action", style: .plain, target: self, action: #selector(performKingfisherAction))
    }
    
    @objc func performKingfisherAction(_ sender: Any) {
        present(alertPopup(sender), animated: true)
    }
}
