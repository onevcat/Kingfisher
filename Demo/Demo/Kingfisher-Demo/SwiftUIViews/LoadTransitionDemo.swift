//
//  LoadTransitionDemo.swift
//  Kingfisher
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
struct LoadTransitionDemo: View {
    @State private var imageIndex = 0
    @State private var currentTransition: TransitionType = .none

    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Image display area
            Group {
                switch currentTransition {
                case .none:
                    KFImage(currentTransition.url)
                        .placeholder { placeholderView }
                        .contentConfigure { content in
                            content
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .forceTransition()
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .fade:
                    KFImage(currentTransition.url)
                        .placeholder { placeholderView }
                        .contentConfigure { content in
                            content
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .forceTransition()
                        .fade(duration: 0.5)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                default:
                    KFImage(currentTransition.url)
                        .placeholder { placeholderView }
                        .contentConfigure { content in
                            content
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .forceTransition()
                        .loadTransition(currentTransition.transition, animation: currentTransition.animation)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .padding(16)
            .frame(width: 300, height: 300)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(16)
            .shadow(radius: 5)

            Spacer()

            // Transition buttons
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(TransitionType.allCases, id: \.self) { type in
                    Button(action: {
                        // Clear cache to ensure transition is visible
                        if let currentURL = URL(string: currentTransition.urlString) {
                            KingfisherManager.shared.cache.removeImage(forKey: currentURL.absoluteString)
                        }
                        currentTransition = type
                    }) {
                        Text(type.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(currentTransition == type ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationBarTitle("Load Transition", displayMode: .inline)
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .overlay(ProgressView())
    }

    enum TransitionType: String, CaseIterable {
        case none = "None"
        case fade = "Fade"
        case slide = "Slide"
        case scale = "Scale"
        case opacity = "Opacity"
        case blurReplace = "Blur"

        @MainActor
        var transition: AnyTransition {
            switch self {
            case .none, .fade:
                return .identity
            case .slide:
                return .slide
            case .scale:
                return .scale
            case .opacity:
                return .opacity
            case .blurReplace:
                if #available(iOS 17.0, *) {
                    return AnyTransition(.blurReplace())
                } else {
                    return .scale  // Fallback for iOS < 17
                }
            }
        }
        
        var animation: Animation? {
            switch self {
            case .none, .fade:
                return nil
            case .slide:
                return .easeInOut(duration: 0.5)
            case .scale:
                return .spring()
            case .opacity:
                return .easeInOut(duration: 0.4)
            case .blurReplace:
                if #available(iOS 17.0, *) {
                    return .bouncy(duration: 0.8)
                } else {
                    return .spring()
                }
            }
        }
        
        var urlString: String {
            let index = TransitionType.allCases.firstIndex(of: self) ?? 0
            let urls = ImageLoader.sampleImageURLs
            return urls[index % urls.count].absoluteString
        }
        
        var url: URL {
            URL(string: urlString)!
        }
    }
}

@available(iOS 14.0, *)
struct LoadTransitionDemo_Previews: PreviewProvider {
    static var previews: some View {
        LoadTransitionDemo()
    }
}
