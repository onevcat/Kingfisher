//
//  SingleViewDemo.swift
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
struct SingleViewDemo : View {

    @State private var index = 1
    @State private var blackWhite = false
    @State private var forceTransition = true

    var url: URL {
        URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher-TestImages/master/DemoAppImage/Loading/kingfisher-\(self.index).jpg")!
    }

    var body: some View {
        VStack {
            KFImage(url)
                .cacheOriginalImage()
                .setProcessor(blackWhite ? BlackWhiteProcessor() : DefaultImageProcessor())
                .onSuccess { r in
                    print("suc: \(r)")
                }
                .onFailure { e in
                    print("err: \(e)")
                }
                .placeholder { progress in
                    ProgressView(progress)
                }
                .fade(duration: index == 1 ? 0 : 1) // Do not animate for the first image. Otherwise it causes an unwanted animation when the page is shown.
                .forceTransition(forceTransition)
                .resizable()
                .frame(width: 300, height: 300)
                .cornerRadius(20)
                .shadow(radius: 5)
                .frame(width: 320, height: 320)

            Button(action: {
                self.index = (self.index % 10) + 1
            }) { Text("Next Image") }
            Button(action: {
                self.blackWhite.toggle()
            }) { Text("Black & White") }
            Toggle("Force Transition?", isOn: $forceTransition)
                .frame(width: 300)

        }.navigationBarTitle(Text("Basic Image"), displayMode: .inline)
    }
}

@available(iOS 14.0, *)
struct SingleViewDemo_Previews : PreviewProvider {
    static var previews: some View {
        SingleViewDemo()
    }
}
