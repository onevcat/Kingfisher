import SwiftUI
import Kingfisher

struct ContentView: View {
    func url(at index: Int) -> URL? {
        let urlPrefix = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher"
        return URL(string: "\(urlPrefix)-\(index + 1).jpg")
    }
    
    var body: some View {
        List {
            ForEach(0 ..< 10) { i in
                HStack {
                    KFImage(url(at: i))
                        .resizable()
                        .roundCorner(
                            radius: .widthFraction(0.5),
                            roundingCorners: [.topLeft, .bottomRight]
                        )
                        .serialize(as: .PNG)
                        .onSuccess { result in
                            print("Image loaded from cache: \(result.cacheType)")
                        }
                        .onFailure { error in
                            print("Error: \(error)")
                        }
                        .frame(width: 64, height: 64)
                    Text("Index \(i)")
                }
            }
        }.listStyle(.plain)
    }
}
