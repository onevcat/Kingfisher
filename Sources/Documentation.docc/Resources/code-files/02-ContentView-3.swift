import SwiftUI
import Kingfisher

struct ContentView: View {
    var body: some View {
        List {
            ForEach(0 ..< 10) { i in
                HStack {
                    Rectangle().fill(Color.gray)
                        .frame(width: 64, height: 64)
                    Text("Index \(i)")
                }
            }
        }.listStyle(.plain)
    }
}
