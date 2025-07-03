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
    public class Context<HoldingView: KFImageHoldingView>: @unchecked Sendable where HoldingView: Sendable {
        
        private let propertyQueue = DispatchQueue(label: "com.onevcat.Kingfisher.KFImageContextPropertyQueue")
        
        let source: Source?
        var _options = KingfisherParsedOptionsInfo(
            KingfisherManager.shared.defaultOptions + [.loadDiskFileSynchronously]
        )
        var options: KingfisherParsedOptionsInfo {
            get { propertyQueue.sync { _options } }
            set { propertyQueue.sync { _options = newValue } }
        }

        var _configurations: [(HoldingView) -> HoldingView] = []
        var configurations: [(HoldingView) -> HoldingView] {
            get { propertyQueue.sync { _configurations } }
            set { propertyQueue.sync { _configurations = newValue } }
        }
        
        var _renderConfigurations: [(HoldingView.RenderingView) -> Void] = []
        var renderConfigurations: [(HoldingView.RenderingView) -> Void] {
            get { propertyQueue.sync { _renderConfigurations } }
            set { propertyQueue.sync { _renderConfigurations = newValue } }
        }
        
        var _contentConfiguration: ((HoldingView) -> AnyView)? = nil
        var contentConfiguration: ((HoldingView) -> AnyView)? {
            get { propertyQueue.sync { _contentConfiguration } }
            set { propertyQueue.sync { _contentConfiguration = newValue } }
        }
        
        var _cancelOnDisappear: Bool = false
        var cancelOnDisappear: Bool {
            get { propertyQueue.sync { _cancelOnDisappear } }
            set { propertyQueue.sync { _cancelOnDisappear = newValue } }
        }

        var _reducePriorityOnDisappear: Bool = false
		var reducePriorityOnDisappear: Bool {
            get { propertyQueue.sync { _reducePriorityOnDisappear } }
            set { propertyQueue.sync { _reducePriorityOnDisappear = newValue } }
        }
        
        var _placeholder: ((Progress) -> AnyView)? = nil
        var placeholder: ((Progress) -> AnyView)? {
            get { propertyQueue.sync { _placeholder } }
            set { propertyQueue.sync { _placeholder = newValue } }
        }

        var _failureView: (() -> AnyView)? = nil
        var failureView: (() -> AnyView)? {
            get { propertyQueue.sync { _failureView } }
            set { propertyQueue.sync { _failureView = newValue } }
        }

        var _startLoadingBeforeViewAppear: Bool = false
        var startLoadingBeforeViewAppear: Bool {
            get { propertyQueue.sync { _startLoadingBeforeViewAppear } }
            set { propertyQueue.sync { _startLoadingBeforeViewAppear = newValue } }
        }

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

#if !os(watchOS)
@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
extension KFAnimatedImage {
    public typealias Context = KFImage.Context
    typealias ImageBinder = KFImage.ImageBinder
}
#endif

#endif
