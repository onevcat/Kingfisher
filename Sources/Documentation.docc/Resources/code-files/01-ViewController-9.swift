//
//  ViewController.swift
//  KingfisherSample
//
//  Created by Wei Wang on 2023/12/12.
//

import UIKit
import Kingfisher

class ViewController: UIViewController {

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.register(SampleCell.self, forCellReuseIdentifier: "SampleCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = 80
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print(KingfisherManager.shared)
        
        tableView.dataSource = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SampleCell", for: indexPath) as! SampleCell
        cell.sampleLabel.text = "Index \(indexPath.row)"
        cell.sampleImageView.backgroundColor = .clear
        
        let urlPrefix = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher"
        let url = URL(string: "\(urlPrefix)-\(indexPath.row + 1).jpg")
        
        cell.sampleImageView.kf.indicatorType = .activity
        
        let roundCorner = RoundCornerImageProcessor(radius: .widthFraction(0.5), roundingCorners: [.topLeft, .bottomRight])
        cell.sampleImageView.kf.setImage(with: url, options: [.processor(roundCorner)]) { result in
            switch result {
            case .success(let imageResult):
                print("Image loaded from cache: \(imageResult.cacheType)")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
        
        return cell
    }
}
