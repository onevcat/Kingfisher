var body: some View {
    List {
        Button("Check Cache") {
            KingfisherManager.shared.cache.calculateDiskStorageSize { result in
                switch result {
                case .success(let size):
                    print("Size: \(Double(size) / 1024 / 1024) MB")
                case .failure(let error):
                    print("Some error: \(error)")
                }
            }
        }
        ForEach(0 ..< 10) { i in
            HStack {
                KFImage(url(at: i))
                // ...
            }
        }
    }.listStyle(.plain)
}
