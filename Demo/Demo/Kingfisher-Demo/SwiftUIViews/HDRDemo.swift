//
//  HDRDemo.swift
//  Kingfisher
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

import Kingfisher
import SwiftUI

/// Shows the same image as SDR and in several HDR formats. Use an HDR display (a recent iPhone or iPad) at a high
/// brightness: with "Prefer HDR" on and "Display" set to "High", the bright parts of the HDR images are brighter than
/// the SDR reference. The pattern has patches at 1x, 2x, 4x and 8x of the SDR white.
@available(iOS 17.0, *)
struct HDRDemo: View {

    enum Subject: String, CaseIterable, Identifiable {
        case photo = "kingfisher"
        case pattern = "pattern"
        var id: String { rawValue }
        var title: String { self == .photo ? "Photo" : "Pattern" }
    }

    enum DisplayRange: String, CaseIterable, Identifiable {
        case standard = "Standard"
        case constrainedHigh = "Constrained"
        case high = "High"
        var id: String { rawValue }
        var value: Image.DynamicRange {
            switch self {
            case .standard: return .standard
            case .constrainedHigh: return .constrainedHigh
            case .high: return .high
            }
        }
    }

    @State private var subject = Subject.photo
    @State private var preferHDR = true
    @State private var displayRange = DisplayRange.high
    @State private var downsample = false
    @State private var backgroundDecode = false
    @State private var reloadToken = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                controls
                ForEach(ImageLoader.HDRImage.allCases) { format in
                    HDRImageCard(
                        url: ImageLoader.hdrImageURL(subject.rawValue, format: format),
                        title: format.title,
                        preferHDR: preferHDR,
                        downsample: downsample,
                        backgroundDecode: backgroundDecode,
                        displayRange: displayRange.value
                    )
                    .id("\(subject.rawValue)-\(format.rawValue)-\(reloadToken)")
                }
            }
            .padding()
        }
        .navigationBarTitle(Text("HDR"), displayMode: .inline)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Image", selection: $subject) {
                ForEach(Subject.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Toggle("Prefer HDR", isOn: $preferHDR)
            Toggle("Downsample", isOn: $downsample)
            Toggle("Background Decode", isOn: $backgroundDecode)
            Picker("Display", selection: $displayRange) {
                ForEach(DisplayRange.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Button("Clear Cache and Reload") {
                KingfisherManager.shared.cache.clearMemoryCache()
                KingfisherManager.shared.cache.clearDiskCache {
                    reloadToken += 1
                }
            }
        }
    }
}

@available(iOS 17.0, *)
private struct HDRImageCard: View {
    let url: URL
    let title: String
    let preferHDR: Bool
    let downsample: Bool
    let backgroundDecode: Bool
    let displayRange: Image.DynamicRange

    @State private var info = "Loading…"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            KFImage(url)
                .preferHighDynamicRange(preferHDR)
                .backgroundDecode(backgroundDecode)
                .setProcessor(
                    downsample
                        ? DownsamplingImageProcessor(size: CGSize(width: 400, height: 400))
                        : DefaultImageProcessor.default
                )
                .onSuccess { result in
                    info = Self.describe(result)
                }
                .onFailure { error in
                    info = "Error: \(error.localizedDescription)"
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .allowedDynamicRange(displayRange)
                .accessibilityIdentifier("hdr-image-\(title)")
            Text(info)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("hdr-info-\(title)")
        }
    }

    private static func describe(_ result: RetrieveImageResult) -> String {
        let image = result.image
        guard let cgImage = image.cgImage else { return "No CGImage" }
        let colorSpace = (cgImage.colorSpace?.name as String?)?
            .replacingOccurrences(of: "kCGColorSpace", with: "") ?? "Unknown"
        let range = image.isHighDynamicRange ? "HDR" : "SDR"
        return "\(range) · \(cgImage.bitsPerComponent) bpc · \(colorSpace) · \(cgImage.width)×\(cgImage.height) · \(result.cacheType)"
    }
}
