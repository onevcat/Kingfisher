//
//  KFImage.swift
//  Kingfisher
//
//  Created by jp20028 on 2019/06/26.
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
import Combine

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
class ImageBinder: BindableObject {
    let url: URL
    var didChange = PassthroughSubject<Kingfisher.Image?, Never>()

    var image: Kingfisher.Image? {
        didSet {
            didChange.send(image)
        }
    }

    init(url: URL) {
        self.url = url
        _ = KingfisherManager.shared.retrieveImage(with: .network(url)) { r in
            switch r {
            case .success(let result): self.image = result.image
            case .failure(let error): break
            }
        }
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public struct KFImage: SwiftUI.View {

    static let empty = Kingfisher.Image()

    private var capInsets: EdgeInsets?
    private var resizingMode: SwiftUI.Image.ResizingMode?

    var config: [(SwiftUI.Image) -> SwiftUI.Image]

    @ObjectBinding var binder: ImageBinder

    public init(url: URL) {
        binder = ImageBinder(url: url)
        config = []
    }

    public var body: some SwiftUI.View {
        #if canImport(UIKit)
        let image = SwiftUI.Image(uiImage: binder.image ?? KFImage.empty)
        #elseif canImport(AppKit)
        let image = SwiftUI.Image(nsImage: binder.image ?? KFImage.empty)
        #endif

        return config.reduce(image) { current, config in config(current) }
    }

    public func resizable(capInsets: EdgeInsets = EdgeInsets(), resizingMode: SwiftUI.Image.ResizingMode = .stretch) -> KFImage {
        var result = self
        result.config.append { $0.resizable(capInsets: capInsets, resizingMode: resizingMode) }
        return result
    }
}

#if DEBUG
struct KFImage_Previews : PreviewProvider {
    static var previews: some SwiftUI.View {
        KFImage(url:URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/logo.png")!)
        .resizable().aspectRatio(contentMode: .fit).padding()
    }
}
#endif
