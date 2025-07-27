//
//  NetworkMetricsViewController.swift
//  Demo
//
//  Created by FunnyValentine on 2025/07/25.
//

import UIKit
import Kingfisher

class NetworkMetricsViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let imageView = UIImageView()
    private let metricsTextView = UITextView()
    private let fromNetworkButton = UIButton(type: .system)
    private let fromMemoryButton = UIButton(type: .system) 
    private let fromDiskButton = UIButton(type: .system)
    private let stackView = UIStackView()
    private let buttonStackView = UIStackView()
    private let metricsContainer = UIView()
    
    // MARK: - Properties
    
    private var currentImageURL = URL(string: "https://picsum.photos/200/150?random=\(Int.random(in: 1...1000))")!
    private var showImage = true
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupInitialContent()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Network Metrics"
        view.backgroundColor = .systemBackground
        
        setupImageView()
        setupMetricsTextView()
        setupButtons()
        setupStackViews()
    }
    
    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear  // Clear background
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupMetricsTextView() {
        metricsTextView.isEditable = false
        metricsTextView.backgroundColor = UIColor.systemGray6
        metricsTextView.layer.cornerRadius = 8
        metricsTextView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        metricsTextView.text = "Tap a button to load image..."
        metricsTextView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupButtons() {
        setupButton(fromNetworkButton, title: "From Network", icon: "wifi", color: .systemRed, action: #selector(fromNetworkButtonTapped))
        setupButton(fromMemoryButton, title: "From Memory", icon: "memorychip", color: .systemOrange, action: #selector(fromMemoryButtonTapped))
        setupButton(fromDiskButton, title: "From Disk", icon: "internaldrive", color: .systemPurple, action: #selector(fromDiskButtonTapped))
    }
    
    private func setupButton(_ button: UIButton, title: String, icon: String, color: UIColor, action: Selector) {
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        
        // Configure image and title positioning
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
    }
    
    private func setupStackViews() {
        // Button stack view
        buttonStackView.axis = .vertical
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 12
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Network button takes full width
        buttonStackView.addArrangedSubview(fromNetworkButton)
        
        // Memory and Disk buttons in horizontal stack
        let horizontalButtonStack = UIStackView()
        horizontalButtonStack.axis = .horizontal
        horizontalButtonStack.distribution = .fillEqually
        horizontalButtonStack.spacing = 12
        horizontalButtonStack.addArrangedSubview(fromMemoryButton)
        horizontalButtonStack.addArrangedSubview(fromDiskButton)
        
        buttonStackView.addArrangedSubview(horizontalButtonStack)
        
        // Main stack view
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center  // Center align all items
        stackView.translatesAutoresizingMaskIntoConstraints = false
        setupMetricsSection()
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(metricsContainer)
        stackView.addArrangedSubview(buttonStackView)
        
        view.addSubview(stackView)
    }
    
    private func setupMetricsSection() {
        metricsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Metrics Information"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        metricsContainer.addSubview(titleLabel)
        metricsContainer.addSubview(metricsTextView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: metricsContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: metricsContainer.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 22),
            
            metricsTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            metricsTextView.leadingAnchor.constraint(equalTo: metricsContainer.leadingAnchor),
            metricsTextView.trailingAnchor.constraint(equalTo: metricsContainer.trailingAnchor),
            metricsTextView.bottomAnchor.constraint(equalTo: metricsContainer.bottomAnchor),
            metricsTextView.heightAnchor.constraint(equalToConstant: 400)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            imageView.heightAnchor.constraint(equalToConstant: 150),
            imageView.widthAnchor.constraint(equalToConstant: 200),

            fromNetworkButton.heightAnchor.constraint(equalToConstant: 44),
            fromMemoryButton.heightAnchor.constraint(equalToConstant: 44),
            fromDiskButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Make button stack view and metrics container full width
            buttonStackView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            
            metricsContainer.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            metricsContainer.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
    }
    
    private func setupInitialContent() {
        // Set initial placeholder
        imageView.image = createPlaceholderImage(text: "Tap button to load")
    }
    
    // MARK: - Actions
    
    @objc private func fromNetworkButtonTapped() {
        // Set placeholder and hide image
        showImage = false
        imageView.image = createPlaceholderImage(text: "Reloading...")
        // Clear all cache to force network download
        KingfisherManager.shared.cache.clearCache()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showImage = true
            self.loadImage()
        }
    }
    
    @objc private func fromMemoryButtonTapped() {
        // Set placeholder and hide image
        showImage = false
        imageView.image = createPlaceholderImage(text: "Reloading...")
        // Clear disk cache only, keep memory cache
        KingfisherManager.shared.cache.clearDiskCache()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showImage = true
            self.loadImage()
        }
    }
    
    @objc private func fromDiskButtonTapped() {
        // Set placeholder and hide image  
        showImage = false
        imageView.image = createPlaceholderImage(text: "Reloading...")
        // Clear memory cache only, keep disk cache
        KingfisherManager.shared.cache.clearMemoryCache()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showImage = true
            self.loadImage()
        }
    }
    
    // MARK: - Image Loading
    
    private func loadImage() {
        guard showImage else { return }
        
        let placeholder = createPlaceholderImage(text: "Loading...")
        
        imageView.kf.setImage(
            with: currentImageURL,
            placeholder: placeholder,
            options: nil,
            completionHandler: { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let retrieveImageResult):
                        self?.displayMetrics(result: retrieveImageResult)
                    case .failure(let error):
                        self?.metricsTextView.text = "Failed to load image: \(error.localizedDescription)"
                        print("Error: \(error)")
                    }
                }
            }
        )
    }
    
    // MARK: - Helper Methods
    
    private func createPlaceholderImage(text: String) -> UIImage {
        let size = CGSize(width: 200, height: 150)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Draw background with rounded corners
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
            UIColor.systemGray5.setFill()
            path.fill()
            
            // Draw text
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.systemGray,
                .font: UIFont.systemFont(ofSize: 16)
            ]
            
            let attributedText = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedText.size()
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            attributedText.draw(in: textRect)
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
            
            // Timing breakdown
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
            
            if let speed = metrics.downloadSpeed {
                info += "Download Speed: \(formatBytes(Int64(speed)))/s"
                info += "\n"
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
        
        metricsTextView.text = info
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
        case 200: return "OK"
        case 201: return "Created"
        case 204: return "No Content"
        case 301: return "Moved Permanently"
        case 302: return "Found"
        case 304: return "Not Modified"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        default: return ""
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
