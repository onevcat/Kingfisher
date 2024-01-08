//
//  SwiftUIViewController.swift
//  Kingfisher
//
//  Created by yeatse on 2024/1/8.
//
//  Copyright (c) 2024 Wei Wang <onevcat@gmail.com>
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

import SwiftUI
import Kingfisher

@available(macOS 11, *)
class SwiftUIViewController: NSHostingController<MainView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: MainView())
    }
}

@available(macOS 11, *)
struct MainView: View {
    @State private var index = 1
    
    static let gifImageURLs: [URL] = {
        let prefix = "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/GIF"
        return (1...3).map { URL(string: "\(prefix)/\($0).gif")! }
    }()
        
    var url: URL {
        MainView.gifImageURLs[index - 1]
    }
    
    var body: some View {
        VStack {
            KFAnimatedImage(url)
                .configure { view in
                    view.framePreloadCount = 3
                }
                .cacheOriginalImage()
                .onSuccess { r in
                    print("suc: \(r)")
                }
                .onFailure { e in
                    print("err: \(e)")
                }
                .placeholder { p in
                    ProgressView(p)
                }
                .fade(duration: 1)
                .forceTransition()
                .aspectRatio(contentMode: .fill)
                .frame(width: 300, height: 300)
                .cornerRadius(20)
                .shadow(radius: 5)
                .frame(width: 320, height: 320)

            Button(action: {
                self.index = (self.index % 3) + 1
            }) { Text("Next Image") }
        }
    }
}
