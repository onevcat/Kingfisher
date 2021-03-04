//
//  GridDemo.swift
//  Kingfisher
//
//  Created by onevcat on 2021/03/02.
//
//  Copyright (c) 2021 Wei Wang <onevcat@gmail.com>
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

@available(iOS 14.0, *)
struct GridDemo: View {

    @State var columns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
    ]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(1..<700) { i in
                    ImageCell(index: i).frame(height: columns.count == 1 ? 300 : 150)
                }
            }
        }.navigationBarTitle(Text("Grid"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {

                    withAnimation(Animation.easeInOut(duration: 0.25)) {
                        self.columns = Array(repeating: .init(.flexible()), count: self.columns.count % 4 + 1)
                    }
                }) {
                    Image(systemName: "square.grid.2x2")
                        .font(.title)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

@available(iOS 14.0, *)
struct GridDemo_Previews: PreviewProvider {
    static var previews: some View {
        GridDemo()
    }
}
