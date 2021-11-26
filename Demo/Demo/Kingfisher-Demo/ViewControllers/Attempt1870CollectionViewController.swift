//
//  Attempt1870CollectionViewController.swift
//  Kingfisher
//
//  Created by shinolr on 2021/11/26.
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

private let reuseIdentifier = "Cell"

class Attempt1870CollectionViewController: UICollectionViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		setupOperationNavigationBar()
		title = "Attempt 1870"
		collectionView.register(Cell.self, forCellWithReuseIdentifier: reuseIdentifier)
	}

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}


	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return ImageLoader.highResolutionImageURLs.count * 30
	}

	//    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
	//    {
	//        (cell as! ImageCollectionViewCell).cellImageView.kf.cancelDownloadTask()
	//    }
	//
	//    override func collectionView(
	//        _ collectionView: UICollectionView,
	//        willDisplay cell: UICollectionViewCell,
	//        forItemAt indexPath: IndexPath)
	//    {
	//        let imageView = (cell as! ImageCollectionViewCell).cellImageView!
	//        let url = ImageLoader.highResolutionImageURLs[indexPath.row % ImageLoader.highResolutionImageURLs.count]
	//        // Use different cache key to prevent reuse the same image. It is just for
	//        // this demo. Normally you can just use the URL to set image.
	//
	//        // This should crash most devices due to memory pressure.
	//        // let resource = ImageResource(downloadURL: url, cacheKey: "\(url.absoluteString)-\(indexPath.row)")
	//        // imageView.kf.setImage(with: resource)
	//
	//        // This would survive on even the lowest spec devices!
	//        KF.url(url, cacheKey: "\(url.absoluteString)-\(indexPath.row)")
	//            .downsampling(size: CGSize(width: 250, height: 250))
	//            .cacheOriginalImage()
	//            .set(to: imageView)
	//    }
	var data: [IndexPath: Bool] = [:]
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! Cell
		print("Load: \(indexPath)")
		if data[indexPath] == nil {
			print("data is nil: \(indexPath)")
			DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
				self.data[indexPath] = true
				self.collectionView.reloadItems(at: [indexPath])
			}
		}

		if data[indexPath] != nil {
			print("data is not nil: \(indexPath)")
			let imageView = cell.cellImageView
			let url = ImageLoader.highResolutionImageURLs[indexPath.row % ImageLoader.highResolutionImageURLs.count]
			KF.url(url, cacheKey: "\(url.absoluteString)-\(indexPath.row)")
				.downsampling(size: imageView.bounds.size)
//				.downsampling(size: .init(width: 250, height: 250))
				.cacheOriginalImage()
				.onSuccess { print("Load done: \(indexPath): \($0)") }
				.onFailure {
					print("cellSize: \(cell.bounds.size)")
					print("imageSize: \(imageView.bounds.size)")
					print("Error: \($0)")
				}
				.set(to: imageView)
		}

		return cell
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showImage" {
			let vc = segue.destination as! DetailImageViewController
			let index = collectionView.indexPathsForSelectedItems![0].row
			vc.imageURL =  ImageLoader.highResolutionImageURLs[index % ImageLoader.highResolutionImageURLs.count]
		}
	}
}

extension Attempt1870CollectionViewController {
	class Cell: UICollectionViewCell {
		let cellImageView = UIImageView(image: nil)

		override init(frame: CGRect) {
			super.init(frame: frame)

			cellImageView.translatesAutoresizingMaskIntoConstraints = false
			contentView.addSubview(cellImageView)
			NSLayoutConstraint.activate([
				cellImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
				cellImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
				cellImageView.widthAnchor.constraint(equalToConstant: 250),
				cellImageView.heightAnchor.constraint(equalToConstant: 250)
			])
		}

		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}

	class Layout: UICollectionViewFlowLayout {
		override func prepare() {
			minimumLineSpacing = 0
			minimumInteritemSpacing = 0
			itemSize = .init(width: UIScreen.main.bounds.width, height: 250)
		}
	}
}
