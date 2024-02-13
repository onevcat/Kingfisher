extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SampleCell", for: indexPath) as! SampleCell
        cell.sampleLabel.text = "Index \(indexPath.row)"
        
        let urlPrefix = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher"
        let url = URL(string: "\(urlPrefix)-1.jpg")
        cell.sampleImageView.kf.setImage(with: url)
        
        cell.sampleImageView.backgroundColor = .lightGray
        return cell
    }
}
