//
//  Box.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/3/17.
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

import Foundation

class Box<T> {
    var value: T

    init(_ value: T) {
        self.value = value
    }
}

/// A `Sendable` box that holds its content weakly.
///
/// It is used to hand a view to escaping download callbacks without extending the view's
/// lifetime. The callbacks retain the box, but the box only references its `value` weakly, so
/// a view whose owner was already released is not kept alive until the download finishes.
/// See https://github.com/onevcat/Kingfisher/issues/2313
///
/// The stored `value` is expected to be accessed on the main thread only (image views are
/// deallocated on the main thread), which is why `@unchecked Sendable` is safe here.
final class WeakBox<T: AnyObject>: @unchecked Sendable {
    weak var value: T?

    init(_ value: T?) {
        self.value = value
    }
}
