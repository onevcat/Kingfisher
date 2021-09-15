//
//  ListDemo.swift
//  Kingfisher
//
//  Created by Wei Wang on 2019/06/18.
//
//  Copyright (c) 2019 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Kingfisher
import SwiftUI

@available(iOS 14.0, *)
struct ListDemo : View {

    var body: some View {
        List(1 ..< 700) { i in
            ImageCell(index: i)
                .frame(height: 300)
        }.navigationBarTitle(Text("SwiftUI List"), displayMode: .inline)
    }
}

@available(iOS 14.0, *)
struct ImageCell: View {

    var alreadyCached: Bool {
        ImageCache.default.isCached(forKey: url.absoluteString)
    }

    let index: Int
    var url: URL {
        URL(string: "https://github.com/onevcat/Flower-Data-Set/raw/master/rose/rose-\(index).jpg")!
    }

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            KFImage.url(url)
                .resizable()
                .onSuccess { r in
                    print("Success: \(self.index) - \(r.cacheType)")
                }
                .onFailure { e in
                    print("Error \(self.index): \(e)")
                }
                .onProgress { downloaded, total in
                    print("\(downloaded) / \(total))")
                }
                .placeholder {
                    HStack {
                        Image(systemName: "arrow.2.circlepath.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding(10)
                        Text("Loading...").font(.title)
                    }
                    .foregroundColor(.gray)
                }
                .fade(duration: 1)
                .cancelOnDisappear(true)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(20)

            Spacer()
        }.padding(.vertical, 12)
    }

}

@available(iOS 14.0, *)
struct SwiftUIList_Previews : PreviewProvider {
    static var previews: some View {
        ListDemo()
    }
}
