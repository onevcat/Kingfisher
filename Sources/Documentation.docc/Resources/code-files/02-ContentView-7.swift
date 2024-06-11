var body: some View {
    List {
        ForEach(0 ..< 10) { i in
            HStack {
                KFImage(url(at: i))
                // ...
            }
        }
    }.listStyle(.plain)
}
