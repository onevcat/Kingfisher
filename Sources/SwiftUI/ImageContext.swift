//
//  ImageContext.swift
//  Kingfisher
//
//  Created by onevcat on 2021/05/08.
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

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImage {
    public class Context<HoldingView: KFImageHoldingView> {
        let source: Source?
        var options = KingfisherParsedOptionsInfo(
            KingfisherManager.shared.defaultOptions + [.loadDiskFileSynchronously]
        )

        var configurations: [(HoldingView) -> HoldingView] = []
        var renderConfigurations: [(HoldingView.RenderingView) -> Void] = []
        
        var cancelOnDisappear: Bool = false
        var placeholder: ((Progress) -> AnyView)? = nil

        let onFailureDelegate = Delegate<KingfisherError, Void>()
        let onSuccessDelegate = Delegate<RetrieveImageResult, Void>()
        let onProgressDelegate = Delegate<(Int64, Int64), Void>()
        
        init(source: Source?) {
            self.source = source
        }
        
        func shouldApplyFade(cacheType: CacheType) -> Bool {
            options.forceTransition || cacheType == .none
        }

        func fadeTransitionDuration(cacheType: CacheType) -> TimeInterval? {
            shouldApplyFade(cacheType: cacheType)
            ? options.transition.fadeDuration
                : nil
        }
    }
}

extension ImageTransition {
    // Only for fade effect in SwiftUI.
    fileprivate var fadeDuration: TimeInterval? {
        switch self {
        case .fade(let duration):
            return duration
        default:
            return nil
        }
    }
}


@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFImage.Context: Hashable {
    public static func == (lhs: KFImage.Context<HoldingView>, rhs: KFImage.Context<HoldingView>) -> Bool {
        lhs.source == rhs.source &&
        lhs.options.processor.identifier == rhs.options.processor.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(options.processor.identifier)
    }
}

#if canImport(UIKit) && !os(watchOS)
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension KFAnimatedImage {
    public typealias Context = KFImage.Context
    typealias ImageBinder = KFImage.ImageBinder
}
#endif

#endif
