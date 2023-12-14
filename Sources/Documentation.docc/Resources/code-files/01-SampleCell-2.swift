//
//  SampleCell.swift
//  KingfisherSample
//
//  Created by Wei Wang on 2023/12/12.
//

import UIKit
import Kingfisher

class SampleCell: UITableViewCell {
    var sampleImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
}
