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
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        KingfisherManager.shared.cache.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                let sizeInMB = Double(size) / 1024 / 1024
                let alert = UIAlertController(title: nil, message: String(format: "Kingfisher Disk Cache: %.2fMB", sizeInMB), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Purge", style: .destructive) { _ in
                    
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                self.present(alert, animated: true)
            case .failure(let error):
                print("Some error: \(error)")
            }
        }
    }
}
