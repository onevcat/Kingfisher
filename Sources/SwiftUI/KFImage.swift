//
//  KFImage.swift
//  Kingfisher
//
//  Created by onevcat on 2019/06/26.
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
extension Image {
    // Creates an SwiftUI.Image with either UIImage or NSImage.
    init(crossPlatformImage: KFCrossPlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: crossPlatformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: crossPlatformImage)
        #endif
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public struct KFImage: View {

    var placeholder = Image(crossPlatformImage: .init())

    var configs: [(Image) -> Image]

    @ObjectBinding public private(set) var binder: ImageBinder

    private let onFailureDelegate = Delegate<KingfisherError, Void>()
    private let onSuccessDelegate = Delegate<RetrieveImageResult, Void>()

    public init(url: URL) {
        binder = ImageBinder(url: url)
        configs = []
    }

    public var body: some View {
        let image = binder.image.map { Image(crossPlatformImage: $0) } ?? placeholder
        return configs
            .reduce(image) { current, config in config(current) }
            .onAppear { [unowned binder] in
                _ = binder.subject.sink(
                    receiveCompletion: { complete in
                        switch complete {
                        case .failure(let error):
                            self.onFailureDelegate.call(error)
                        case .finished:
                            break
                        }
                    },
                    receiveValue: { result in
                        self.onSuccessDelegate.call(result)
                    }
                )
                print("Start!! \(binder.url)")
                binder.start()
            }
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {

    public func config(_ block: @escaping (Image) -> Image) -> KFImage {
        var result = self
        result.configs.append(block)
        return result
    }

    public func resizable(
        capInsets: EdgeInsets = EdgeInsets(),
        resizingMode: Image.ResizingMode = .stretch) -> KFImage
    {
        config { $0.resizable(capInsets: capInsets, resizingMode: resizingMode) }
    }

    public func renderingMode(_ renderingMode: Image.TemplateRenderingMode?) -> KFImage {
        config { $0.renderingMode(renderingMode) }
    }

    public func interpolation(_ interpolation: Image.Interpolation) -> KFImage {
        config { $0.interpolation(interpolation) }
    }

    public func antialiased(_ isAntialiased: Bool) -> KFImage {
        config { $0.antialiased(isAntialiased) }
    }

    public func placeholder(image: Image?) -> KFImage {
        var result = self
        result.placeholder = image ?? Image(crossPlatformImage: .init())
        return result
    }

    public func placeholder(name: String, bundle: Bundle? = nil) -> KFImage {
        return placeholder(image: .init(name, bundle: bundle))
    }

    public func placeholder(systemName: String) -> KFImage {
        return placeholder(image: .init(systemName: systemName))
    }
}

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {
    public func onFailure(perform action: ((Error) -> Void)?) -> KFImage {
        onFailureDelegate.delegate(on: binder) { _, error in
            action?(error)
        }
        return self
    }

    public func onSuccess(perform action: ((RetrieveImageResult) -> Void)?) -> KFImage {
        onSuccessDelegate.delegate(on: binder) { _, result in
            action?(result)
        }
        return self
    }
}

#if DEBUG
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct KFImage_Previews : PreviewProvider {
    static var previews: some View {
        KFImage(url:URL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/logo.png")!)
        .onSuccess { r in
            print(r)
        }
        .resizable()
        .aspectRatio(contentMode: .fit)
        .padding()
    }
}
#endif
