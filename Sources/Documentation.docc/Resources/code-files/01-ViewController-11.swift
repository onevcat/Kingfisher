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
                print("Size: \(Double(size) / 1024 / 1024) MB")
            case .failure(let error):
                print("Some error: \(error)")
            }
        }
    }
}
