//
//  MainView.swift
//  Kingfisher
//
//  Created by onevcat on 2019/08/07.
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

import SwiftUI
import Kingfisher

@available(iOS 14.0, *)
struct MainView: View {
    var body: some View {
        List {
            Section {
                Button(
                    action: {
                        KingfisherManager.shared.cache.clearMemoryCache()
                        KingfisherManager.shared.cache.clearDiskCache()
                    },
                    label: {
                        Text("Clear Cache").foregroundColor(.blue)
                    }
                )
            }
            
            Section(header: Text("Demo")) {
                NavigationLink(destination: SingleViewDemo()) { Text("Basic Image") }
                NavigationLink(destination: SizingAnimationDemo()) { Text("Sizing Toggle") }
                NavigationLink(destination: ListDemo()) { Text("List") }
                NavigationLink(destination: LazyVStackDemo()) { Text("Stack") }
                NavigationLink(destination: GridDemo()) { Text("Grid") }
                NavigationLink(destination: AnimatedImageDemo()) { Text("Animated Image") }
                NavigationLink(destination: GeometryReaderDemo()) { Text("Geometry Reader") }
                NavigationLink(destination: TransitionViewDemo()) { Text("Transition") }
            }
            
            Section(header: Text("Regression Cases")) {
                NavigationLink(destination: Issue1998View()) { Text("#1998") }
                NavigationLink(destination: Issue2035View()) { Text("#2035") }
            }
        }.navigationBarTitle(Text("SwiftUI Sample"))
    }
}

@available(iOS 14.0, *)
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
