@State var showAlert = false
@State var cacheSizeResult: Result<UInt, KingfisherError>? = nil

var body: some View {
    List {
        Button("Check Cache") {
            KingfisherManager.shared.cache.calculateDiskStorageSize { result in
                cacheSizeResult = result
                showAlert = true
            }
        }
        .alert(
            "Disk Cache",
            isPresented: $showAlert,
            presenting: cacheSizeResult,
            actions: { result in
                // TODO: Actions
            }, message: { result in
                switch result {
                case .success(let size):
                    Text("Size: \(Double(size) / 1024 / 1024) MB")
                case .failure(let error):
                    Text(error.localizedDescription)
                }
            })
        
        ForEach(0 ..< 10) { i in
            HStack {
                KFImage(url(at: i))
                // ...
            }
        }
    }.listStyle(.plain)
}
