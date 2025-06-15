<!-- Generated: 2025-06-15 10:30:00 UTC -->

# Kingfisher Architecture Documentation

## High-Level System Organization

Kingfisher is a sophisticated image loading and caching library for Apple platforms, designed with a modular architecture that promotes separation of concerns and extensibility. At its core, the library employs a coordinator pattern where `KingfisherManager` serves as the central orchestrator, managing the flow between network operations, caching layers, and image processing pipelines. The architecture leverages protocol-oriented design principles, with all functionality exposed through a `.kf` namespace wrapper that provides a clean, chainable API surface.

The system is built on three fundamental pillars: downloading, caching, and processing. The `ImageDownloader` handles all network operations with support for authentication, retries, and progressive loading. The `ImageCache` implements a dual-layer caching strategy combining memory and disk storage for optimal performance. The `ImageProcessor` protocol enables a flexible transformation pipeline where multiple processors can be chained together. These components work in concert through a sophisticated options system (`KingfisherOptionsInfo`) that allows fine-grained control over every aspect of the image loading process.

Cross-platform compatibility is achieved through extensive use of conditional compilation and type aliases, allowing the same codebase to support iOS, macOS, tvOS, watchOS, and visionOS. The library provides both UIKit/AppKit extensions and dedicated SwiftUI components (`KFImage`, `KFAnimatedImage`), ensuring seamless integration regardless of the UI framework being used.

## Component Map

### Core Components

| Component | Location | Purpose |
|-----------|----------|---------|
| **KingfisherManager** | `Sources/General/KingfisherManager.swift` | Central coordinator managing image retrieval, caching, and processing workflows |
| **ImageDownloader** | `Sources/Networking/ImageDownloader.swift` | Handles all network operations for downloading images |
| **ImageCache** | `Sources/Cache/ImageCache.swift` | Dual-layer caching system with memory and disk storage |
| **ImageProcessor** | `Sources/Image/ImageProcessor.swift` | Protocol and implementations for image transformation pipeline |
| **KF** | `Sources/General/KF.swift` | Builder pattern entry point for fluent API |
| **Source** | `Sources/General/ImageSource/Source.swift` | Represents image data sources (network/provider) |
| **Resource** | `Sources/General/ImageSource/Resource.swift` | Protocol for cacheable resources with key/URL |

### Storage Layer

| Component | Location | Purpose |
|-----------|----------|---------|
| **MemoryStorage** | `Sources/Cache/MemoryStorage.swift` | In-memory cache implementation with LRU eviction |
| **DiskStorage** | `Sources/Cache/DiskStorage.swift` | File-based cache with expiration and size limits |
| **CacheSerializer** | `Sources/Cache/CacheSerializer.swift` | Handles image data serialization for cache storage |

### Networking Layer

| Component | Location | Purpose |
|-----------|----------|---------|
| **SessionDelegate** | `Sources/Networking/SessionDelegate.swift` | URLSession delegate for download management |
| **SessionDataTask** | `Sources/Networking/SessionDataTask.swift` | Wrapper for URLSessionDataTask with cancellation |
| **ImagePrefetcher** | `Sources/Networking/ImagePrefetcher.swift` | Preloads images for improved performance |
| **RequestModifier** | `Sources/Networking/RequestModifier.swift` | Protocol for modifying URL requests |
| **RetryStrategy** | `Sources/Networking/RetryStrategy.swift` | Configurable retry logic for failed downloads |

### UI Integration

| Component | Location | Purpose |
|-----------|----------|---------|
| **ImageView+Kingfisher** | `Sources/Extensions/ImageView+Kingfisher.swift` | UIImageView/NSImageView extensions |
| **KFImage** | `Sources/SwiftUI/KFImage.swift` | SwiftUI image component |
| **KFAnimatedImage** | `Sources/SwiftUI/KFAnimatedImage.swift` | SwiftUI animated image support |
| **AnimatedImageView** | `Sources/Views/AnimatedImageView.swift` | GIF animation support view |

## Key Files

### KingfisherManager.swift (Lines 107-420)
The heart of the library, containing:
- `shared` singleton instance (line 113)
- `retrieveImage()` main entry point (lines 196-210, 233-248)
- Cache lookup logic (lines 400-403)
- Download coordination (lines 415-418)
- Retry and alternative source handling (lines 306-385)

### ImageDownloader.swift (Lines 35-150)
Network layer implementation:
- `ImageLoadingResult` struct for download results (lines 36-58)
- `DownloadTask` class for cancellable downloads (lines 65-102)
- URLSession management and request handling

### ImageCache.swift (Lines 52-200)
Caching infrastructure:
- `CacheType` enum defining cache levels (lines 52-72)
- Memory and disk cache coordination
- Cache key generation and expiration logic

### KF.swift (Lines 50-100)
Builder pattern implementation:
- Static factory methods for creating builders (lines 56-99)
- Fluent API entry points for different source types

### ImageProcessor.swift (Lines 37-100)
Processing pipeline:
- `ImageProcessItem` enum for input types (lines 37-46)
- `ImageProcessor` protocol definition (lines 49-76)
- Processor chaining via `append()` (lines 85-95)

### KingfisherOptionsInfo.swift (Lines 43-250)
Configuration system:
- Option items enumeration with associated values
- Cache, downloader, and processor configuration
- Transition and placeholder settings

## Data Flow

### 1. Image Request Initiation

```
UIImageView.kf.setImage(with: url)
    │
    └─> ImageView+Kingfisher.swift (line 77-87)
        │
        └─> KingfisherManager.retrieveImage()
            Sources/General/KingfisherManager.swift (line 196)
```

### 2. Cache Lookup

```
KingfisherManager.retrieveImage()
    │
    └─> retrieveImageFromCache() (line 400)
        │
        ├─> ImageCache.retrieveImage()
        │   Sources/Cache/ImageCache.swift
        │   │
        │   ├─> MemoryStorage.value(forKey:)
        │   │   Sources/Cache/MemoryStorage.swift
        │   │
        │   └─> DiskStorage.value(forKey:)
        │       Sources/Cache/DiskStorage.swift
        │
        └─> [Cache Hit] → completionHandler(.success)
            [Cache Miss] → Continue to download
```

### 3. Network Download

```
KingfisherManager.loadAndCacheImage() (line 415)
    │
    └─> ImageDownloader.downloadImage()
        Sources/Networking/ImageDownloader.swift
        │
        ├─> SessionDelegate.downloadTask()
        │   Sources/Networking/SessionDelegate.swift
        │
        └─> URLSession.dataTask()
            │
            └─> CompletionHandler with ImageLoadingResult
```

### 4. Image Processing

```
Downloaded Data
    │
    └─> ImageProcessor.process() (line 434)
        Sources/Image/ImageProcessor.swift
        │
        ├─> DefaultImageProcessor (if none specified)
        │
        └─> Custom processors chain
            │
            └─> Processed KFCrossPlatformImage
```

### 5. Cache Storage

```
Processed Image
    │
    └─> KingfisherManager.cacheImage() (line 459)
        │
        ├─> ImageCache.store() (line 482)
        │   │
        │   ├─> MemoryStorage.store()
        │   │   In-memory cache with cost calculation
        │   │
        │   └─> DiskStorage.store()
        │       File system with expiration
        │
        └─> completionHandler(.success(RetrieveImageResult))
            │
            └─> UI Update on main queue
```

### 6. Error Handling and Retry

```
Download/Processing Error
    │
    └─> RetryStrategy.retry() (line 362)
        Sources/Networking/RetryStrategy.swift
        │
        ├─> [Retry] → startNewRetrieveTask() (line 306)
        │
        └─> [No Retry] → Check alternative sources (line 334)
            │
            ├─> [Alternative exists] → Start new task
            │
            └─> [No alternatives] → completionHandler(.failure)
```

This architecture enables Kingfisher to efficiently handle image loading with features like progressive downloading, multiple cache layers, flexible processing pipelines, and robust error handling, all while maintaining a clean and intuitive API surface for developers.