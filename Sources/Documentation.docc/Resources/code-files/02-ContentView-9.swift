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
        ForEach(0 ..< 10) { i in
            HStack {
                KFImage(url(at: i))
                // ...
            }
        }
    }.listStyle(.plain)
}
