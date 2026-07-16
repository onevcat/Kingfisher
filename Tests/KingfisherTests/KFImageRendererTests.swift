//
//  KFImageRendererTests.swift
//  Kingfisher
//
//  Created by kjy on 7/9/26.
//
//  Copyright (c) 2026 Wei Wang <onevcat@gmail.com>
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


#if canImport(SwiftUI) && canImport(UIKit) && (os(iOS) || os(tvOS))

import SwiftUI
import UIKit
import XCTest
@testable import Kingfisher

@available(iOS 14.0, tvOS 14.0, *)
class KFImageRendererTests: XCTestCase {
    // MARK: - Layout
    @MainActor
    func testPlaceholderDefinesLayoutWhenLoadedImageIsNil() async {
        let maxHeight: CGFloat = 200

        let view = KFImage.dataProvider(nil)
            .resizable()
            .placeholder {
                Color.gray
                    .frame(maxHeight: maxHeight)
            }
            .aspectRatio(contentMode: .fit)

        let measuredSize = await measureLayout(view)

        XCTAssertEqual(
            measuredSize.height,
            maxHeight,
            accuracy: 0.5,
            "The placeholder should define the KFImage layout while loadedImage is nil. Before the fix, the empty image branch still participated in layout and made KFImage taller than the placeholder."
        )
    }

    @MainActor
    func testFailureViewDefinesLayoutWhenLoadedImageIsNil() async {
        let maxHeight: CGFloat = 200
        let failureExpectation = expectation(description: "Image loading fails")

        let view = KFImage.dataProvider(FailingImageDataProvider())
            .resizable()
            .onFailureView {
                Color.red
                    .frame(maxHeight: maxHeight)
            }
            .onFailure { _ in
                failureExpectation.fulfill()
            }
            .aspectRatio(contentMode: .fit)

        let measuredSize = await measureLayout(view, after: failureExpectation)

        XCTAssertEqual(
            measuredSize.height,
            maxHeight,
            accuracy: 0.5,
            "The failure view should define the KFImage layout while loadedImage is nil. Before the fix, the empty image branch still participated in layout and made KFImage taller than the failure view."
        )
    }

    @MainActor
    private func measureLayout<V: View>(
        _ view: V,
        after expectation: XCTestExpectation? = nil
    ) async -> CGSize {
        let width: CGFloat = 390
        let height: CGFloat = 800

        var measuredSize = CGSize.zero

        let rootView = VStack(spacing: 0) {
            view
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                measuredSize = proxy.size
                            }
                            .onChange(of: proxy.size) { newSize in
                                measuredSize = newSize
                            }
                    }
                )

            Spacer()
        }
        .frame(width: width, height: height)

        let controller = UIHostingController(rootView: rootView)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = controller
        window.makeKeyAndVisible()

        if let expectation {
            await fulfillment(of: [expectation], timeout: 1)
        }

        for _ in 0..<5 {
            await Task.yield()
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
        }

        window.isHidden = true
        return measuredSize
    }

    // MARK: - Renderer intermediate states
    @MainActor
    func testOpacityRendererKeepsPlaceholderWhileImageIsPrepared() async {
        await assertPlaceholderIsRenderedWhileImageIsPrepared(swiftUITransition: nil)
    }

    @MainActor
    func testLoadTransitionKeepsPlaceholderWhileImageIsPrepared() async {
        await assertPlaceholderIsRenderedWhileImageIsPrepared(swiftUITransition: .opacity)
    }

    @MainActor
    private func assertPlaceholderIsRenderedWhileImageIsPrepared(swiftUITransition: AnyTransition?) async {
        let placeholderAppeared = expectation(description: "Placeholder appeared")

        let binder = KFImage.ImageBinder()
        // Simulates the render pass after `loadedImage` changes but before `loaded` does.
        binder.loadedImage = testImage

        let context = KFImage.Context<Image>(source: nil)
        context.swiftUITransition = swiftUITransition
        context.placeholder = { _ in
            AnyView(
                Color.gray
                    .frame(height: 200)
                    .onAppear {
                        placeholderAppeared.fulfill()
                    }
            )
        }

        let view = KFImageRenderer(context: context, binder: binder)

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 390, height: 800))
        window.rootViewController = controller
        window.makeKeyAndVisible()

        await fulfillment(of: [placeholderAppeared], timeout: 1)
        window.isHidden = true
    }

    // MARK: - Non-cached loading paths
    @MainActor
    func testFadeUsesFadePathForNonCachedImage() async {
        let loaded = expectation(description: "Image loads from provider")

        let view = makeNonCachedImage()
            .resizable()
            .placeholder {
                Color.gray.frame(height: 200)
            }
            .fade(duration: 0.2)
            .onSuccess { result in
                XCTAssertEqual(result.cacheType, .none)
                loaded.fulfill()
            }

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 390, height: 800))
        window.rootViewController = controller
        window.makeKeyAndVisible()

        await fulfillment(of: [loaded], timeout: 1)
        window.isHidden = true
    }

    @MainActor
    func testLoadTransitionUsesLoadTransitionPathForNonCachedImage() async {
        let loaded = expectation(description: "Image loads from provider")

        let view = makeNonCachedImage()
            .resizable()
            .placeholder {
                Color.gray.frame(height: 200)
            }
            .loadTransition(.opacity)
            .onSuccess { result in
                XCTAssertEqual(result.cacheType, .none)
                loaded.fulfill()
            }

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 390, height: 800))
        window.rootViewController = controller
        window.makeKeyAndVisible()

        await fulfillment(of: [loaded], timeout: 1)
        window.isHidden = true
    }

    @MainActor
    private func makeNonCachedImage() -> KFImage {
        KFImage.data(
            testImagePNGData,
            cacheKey: "com.onevcat.KingfisherTests.\(UUID().uuidString)"
        )
    }

    // MARK: - External transition
    @MainActor
    func testRendererKeepsImageBranchBeforeImageLoads() async {
        let imageBranchAppeared = expectation(description: "Image branch appeared")

        let binder = KFImage.ImageBinder()
        let context = KFImage.Context<Image>(source: nil)
        // Keep the image branch in the hierarchy before a cache hit resolves.
        context.contentConfiguration = { _ in
            AnyView(
                Color.clear
                    .onAppear {
                        imageBranchAppeared.fulfill()
                    }
            )
        }

        let view = KFImageRenderer(context: context, binder: binder)

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 390, height: 800))
        window.rootViewController = controller
        window.makeKeyAndVisible()

        await fulfillment(of: [imageBranchAppeared], timeout: 1)
        window.isHidden = true
    }

    @MainActor
    func testExternalTransitionPreservesCachedImageInsertion() async throws {
        let cache = ImageCache(name: "com.onevcat.KingfisherTests.ExternalTransition.\(UUID().uuidString)")
        let url = URL(string: "https://example.com/image.png")!
        try await cache.store(testImage, forKey: url.cacheKey, toDisk: false)

        let state = ExternalTransitionState()
        let loaded = expectation(description: "Cached image loads")

        let view = ExternalTransitionHost(
            state: state,
            url: url,
            cache: cache,
            onSuccess: { result in
                XCTAssertEqual(result.cacheType, .memory)
                loaded.fulfill()
            }
        )

        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 800))
        window.rootViewController = controller
        window.makeKeyAndVisible()

        for _ in 0..<2 {
            await Task.yield()
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
        }

        withAnimation(.linear(duration: 0.2)) {
            state.showImage = true
        }

        await fulfillment(of: [loaded], timeout: 1)
        window.isHidden = true
    }
}

@MainActor
private final class ExternalTransitionState: ObservableObject {
    @Published var showImage = false
}

@available(iOS 14.0, tvOS 14.0, *)
private struct ExternalTransitionHost: View {
    @ObservedObject var state: ExternalTransitionState
    let url: URL
    let cache: ImageCache
    let onSuccess: (RetrieveImageResult) -> Void

    var body: some View {
        ZStack {
            if state.showImage {
                KFImage(url)
                    .targetCache(cache)
                    .onSuccess { result in
                        onSuccess(result)
                    }
                    .resizable()
                    .frame(width: 100, height: 100)
                    .transition(.slide)
            }
        }
        .frame(width: 390, height: 200)
    }
}

private struct FailingImageDataProvider: ImageDataProvider {
    let cacheKey = "com.onevcat.KingfisherTests.FailingImageDataProvider"

    func data() async throws -> Data {
        throw Error()
    }

    struct Error: Swift.Error {}
}

#endif
