//
//  NetworkMetricsDemo.swift
//  Demo
//
//  Created by FunnyValentine on 2025/07/25.
//

import SwiftUI
import Kingfisher

@available(iOS 14.0, *)
struct NetworkMetricsDemo: View {
    @State private var imageURL = URL(string: "https://picsum.photos/200/150?random=\(Int.random(in: 1...1000))")!
    @State private var metricsInfo = "Tap a button to load image..."
    @State private var isLoading = false
    @State private var showImage = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                imageSection
                metricsInfoSection
                buttonsSection
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Network Metrics")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - UI Components
    
    private var imageSection: some View {
        VStack {
            if showImage {
                KFImage(imageURL)
                    .onProgress { _, _ in
                        isLoading = true
                    }
                    .onSuccess { result in
                        isLoading = false
                        displayMetrics(result: result)
                    }
                    .onFailure { error in
                        isLoading = false
                        metricsInfo = "Failed to load image: \(error.localizedDescription)"
                        print("error: \(error)")
                    }
                    .placeholder {
                        placeholderView(text: isLoading ? "Loading..." : "Tap button to load")
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                placeholderView(text: "Reloading...")
            }
        }
        .frame(width: 200, height: 150)
        .padding(.bottom, 10)
    }
    
    private var metricsInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metrics Information")
                .font(.headline)
            
            VStack {
                Text(metricsInfo)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                Spacer()
            }
            .frame(height: 400)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var buttonsSection: some View {
        VStack(spacing: 12) {
            actionButton(
                title: "From Network",
                icon: "wifi",
                color: .red,
                action: loadFromNetwork
            )
            
            HStack(spacing: 12) {
                actionButton(
                    title: "From Memory",
                    icon: "memorychip",
                    color: .orange,
                    action: loadFromMemory
                )
                
                actionButton(
                    title: "From Disk",
                    icon: "internaldrive",
                    color: .purple,
                    action: loadFromDisk
                )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func placeholderView(text: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 200, height: 150)
            .overlay(
                Text(text)
                    .foregroundColor(.gray)
            )
    }
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func loadFromNetwork() {
        // Refresh image
        showImage = false
        // Clear all cache to force network download
        KingfisherManager.shared.cache.clearCache()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showImage = true
        }
    }
    
    private func loadFromMemory() {
        // Refresh image
        showImage = false
        // Clear disk cache only, keep memory cache
        KingfisherManager.shared.cache.clearDiskCache()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showImage = true
        }
    }
    
    private func loadFromDisk() {
        // Refresh image
        showImage = false
        // Clear memory cache only, keep disk cache
        KingfisherManager.shared.cache.clearMemoryCache()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showImage = true
        }
    }
    
    private func displayMetrics(result: RetrieveImageResult) {
        var info = "=== Image Load Results ===\n\n"
        
        // Basic info
        info += "Cache Type: \(cacheTypeDescription(result.cacheType))\n\n"
        
        // Network Metrics
        if let metrics = result.metrics {
            info += "=== Network Metrics ===\n"
            info += "✅ Downloaded from network\n\n"
            
            // Timing metrics
            info += "📊 Timing Breakdown:\n"
            info += "Total Request: \(String(format: "%.3f", metrics.totalRequestDuration))s\n"

            if let dnsTime = metrics.domainLookupDuration {
                info += "DNS Lookup: \(String(format: "%.3f", dnsTime))s\n"
            } else {
                info += "DNS Lookup: N/A (cached or skipped)\n"
            }
            
            if let connectTime = metrics.connectDuration {
                info += "TCP Connect: \(String(format: "%.3f", connectTime))s\n"
            } else {
                info += "TCP Connect: N/A (reused connection)\n"
            }
            
            if let tlsTime = metrics.secureConnectionDuration {
                info += "TLS Handshake: \(String(format: "%.3f", tlsTime))s\n"
            } else {
                info += "TLS Handshake: N/A (HTTP or reused)\n"
            }
            
            // Data transfer
            info += "\n📈 Data Transfer:\n"
            info += "Request Body: \(formatBytes(metrics.requestBodyBytesSent))\n"
            info += "Response Body: \(formatBytes(metrics.responseBodyBytesReceived))\n"
            
            if metrics.responseBodyBytesReceived > 0 {
                let speed = Double(metrics.responseBodyBytesReceived) / metrics.totalRequestDuration
                info += "Download Speed: \(formatBytes(Int64(speed)))/s\n"
            }
            
            // HTTP details
            info += "\n🌐 HTTP Details:\n"
            if let statusCode = metrics.httpStatusCode {
                info += "Status Code: \(statusCode) \(httpStatusDescription(statusCode))\n"
            }
            info += "Redirects: \(metrics.redirectCount)\n"
            
            
        } else {
            info += "=== Network Metrics ===\n"
            info += "💾 Loaded from cache\n"
            info += "No network request was made\n\n"
            
            info += "This image was served from:\n"
            switch result.cacheType {
            case .memory:
                info += "• Memory cache (fastest)\n"
            case .disk:
                info += "• Disk cache (fast)\n"
            case .none:
                info += "• Network (but no metrics available)\n"
            @unknown default:
                info += "• Unknown cache type\n"
            }
        }
        
        metricsInfo = info
    }
    
    private func cacheTypeDescription(_ cacheType: CacheType) -> String {
        switch cacheType {
        case .memory:
            return "Memory Cache 🚀"
        case .disk:
            return "Disk Cache 💽"
        case .none:
            return "Network Download 🌐"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func httpStatusDescription(_ statusCode: Int) -> String {
        switch statusCode {
        case 200:
            return "OK"
        case 201:
            return "Created"
        case 204:
            return "No Content"
        case 301:
            return "Moved Permanently"
        case 302:
            return "Found"
        case 304:
            return "Not Modified"
        case 400:
            return "Bad Request"
        case 401:
            return "Unauthorized"
        case 403:
            return "Forbidden"
        case 404:
            return "Not Found"
        case 500:
            return "Internal Server Error"
        default:
            return ""
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

@available(iOS 14.0, *)
struct NetworkMetricsDemo_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NetworkMetricsDemo()
        }
    }
}
