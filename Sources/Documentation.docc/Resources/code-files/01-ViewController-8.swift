extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SampleCell", for: indexPath) as! SampleCell
        cell.sampleLabel.text = "Index \(indexPath.row)"
        
        let urlPrefix = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher"
        let url = URL(string: "\(urlPrefix)-\(indexPath.row + 1).jpg")
        
        cell.sampleImageView.kf.indicatorType = .activity
        
        let roundCorner = RoundCornerImageProcessor(radius: .widthFraction(0.5), roundingCorners: [.topLeft, .bottomRight])
        let pngSerializer = FormatIndicatedCacheSerializer.png
        cell.sampleImageView.kf.setImage(
            with: url,
            options: [.processor(roundCorner), .cacheSerializer(pngSerializer)]
        )
        cell.sampleImageView.backgroundColor = .clear
        return cell
    }
}
