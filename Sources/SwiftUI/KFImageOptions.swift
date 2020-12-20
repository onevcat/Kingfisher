//
//  KFImageOptions.swift
//  Kingfisher
//
//  Created by onevcat on 2020/12/20.
//
//  Copyright (c) 2020 Wei Wang <onevcat@gmail.com>
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

// MARK: - KFImage creating.
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
extension KFImage {
    public static func source(
        _ source: Source, loadingState: Binding<KFImageLoadingState>? = nil
    ) -> KFImage
    {
        KFImage(source: source, loadingState: loadingState)
    }

    public static func resource(
        _ resource: Resource, loadingState: Binding<KFImageLoadingState>? = nil
    ) -> KFImage
    {
        .source(.network(resource), loadingState: loadingState)
    }

    public static func url(
        _ url: URL, cacheKey: String? = nil, loadingState: Binding<KFImageLoadingState>? = nil
    ) -> KFImage
    {
        source(.network(ImageResource(downloadURL: url, cacheKey: cacheKey)), loadingState: loadingState)
    }

    public static func dataProvider(
        _ provider: ImageDataProvider, loadingState: Binding<KFImageLoadingState>? = nil
    ) -> KFImage
    {
        source(.provider(provider), loadingState: loadingState)
    }

    public static func data(
        _ data: Data, cacheKey: String, loadingState: Binding<KFImageLoadingState>? = nil
    ) -> KFImage
    {
        source(.provider(RawImageDataProvider(data: data, cacheKey: cacheKey)), loadingState: loadingState)
    }
}
