//
//  LoadingFailureDemo.swift
//  Kingfisher
//
//  Created by onevcat on 2025/06/29.
//
//  Copyright (c) 2025 Wei Wang <onevcat@gmail.com>
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
struct LoadingFailureDemo: View {

    var url: URL {
        URL(string: "https://example.com")!
    }
    
    var warningImage: UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: 50)
        return UIImage(
            systemName: "wrongwaysign",
            withConfiguration: config
        )!
    }
    
    var body: some View {
        VStack {
            KFImage(url)
                .onFailureView {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.red.opacity(0.5))
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .frame(width: 50, height: 47)
                            .foregroundColor(.yellow)
                    }
                }
                .frame(width: 200, height: 200)
            Text("onFailureView")
            Spacer().frame(height: 20)
            
            KFImage(url)
                .onFailureImage(warningImage)
                .frame(width: 200, height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.red.opacity(0.5))
                )
            Text("onFailureImage")
        }
    }
}

@available(iOS 14.0, *)
struct LoadingFailureDemo_Previews: PreviewProvider {
    static var previews: some View {
        LoadingFailureDemo()
    }
}
