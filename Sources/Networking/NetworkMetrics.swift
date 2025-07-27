//
//  NetworkMetrics.swift
//  Kingfisher
//
//  Created by FunnyValentine on 2025/07/25.
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

import Foundation

/// Represents the network performance metrics collected during an image download task.
public struct NetworkMetrics: Sendable {

    /// The original URLSessionTaskMetrics for advanced use cases.
    public let rawMetrics: URLSessionTaskMetrics

    /// The duration of the actual image retrieval (excluding redirects).
    public let retrieveImageDuration: TimeInterval?

    /// The total time from request start to completion (including redirects).
    public let totalRequestDuration: TimeInterval

    /// The time it took to perform DNS lookup.
    public let domainLookupDuration: TimeInterval?
    
    /// The time it took to establish the TCP connection.
    public let connectDuration: TimeInterval?
    
    /// The time it took to perform TLS handshake.
    public let secureConnectionDuration: TimeInterval?
    
    /// The number of bytes sent in the request body.
    public let requestBodyBytesSent: Int64
    
    /// The number of bytes received in the response body.
    public let responseBodyBytesReceived: Int64
    
    /// The HTTP response status code, if available.
    public let httpStatusCode: Int?
    
    /// The number of redirects that occurred during the request.
    public let redirectCount: Int
    
    /// Creates a NetworkMetrics instance from URLSessionTaskMetrics
    init?(from urlMetrics: URLSessionTaskMetrics) {
        // Find the first successful transaction (200-299 status) ignoring redirects
        // We need to ensure we get metrics from an actual successful download, not from 
        // intermediate redirects (301/302) which don't represent real download performance
        var successfulTransaction: URLSessionTaskTransactionMetrics?
        for transaction in urlMetrics.transactionMetrics {
            if let httpResponse = transaction.response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                successfulTransaction = transaction
                break
            }
        }

        // make sure we have a valid successful transaction
        guard let successfulTransaction else {
            return nil
        }

        // Store raw metrics for advanced use cases
        self.rawMetrics = urlMetrics
        
        // Calculate the image retrieval duration from the successful transaction
        self.retrieveImageDuration = Self.calculateRetrieveImageDuration(from: successfulTransaction)
        
        // Calculate the total request duration from the task interval
        self.totalRequestDuration = urlMetrics.taskInterval.duration
        
        // Calculate timing metrics from the successful transaction
        self.domainLookupDuration = Self.calculateDomainLookupDuration(from: successfulTransaction)
        self.connectDuration = Self.calculateConnectDuration(from: successfulTransaction)
        self.secureConnectionDuration = Self.calculateSecureConnectionDuration(from: successfulTransaction)
        
        // Extract data transfer information from the successful transaction
        self.requestBodyBytesSent = successfulTransaction.countOfRequestBodyBytesSent
        self.responseBodyBytesReceived = successfulTransaction.countOfResponseBodyBytesReceived
        
        // Extract HTTP status code from the successful transaction
        self.httpStatusCode = Self.extractHTTPStatusCode(from: successfulTransaction)
        
        // Extract redirect count
        self.redirectCount = urlMetrics.redirectCount
    }
    
    // MARK: - Private Calculation Methods
    
    /// Calculates DNS lookup duration
    /// Formula: domainLookupEndDate - domainLookupStartDate
    /// Represents: Time spent resolving domain name to IP address
    private static func calculateDomainLookupDuration(from transaction: URLSessionTaskTransactionMetrics) -> TimeInterval? {
        guard let start = transaction.domainLookupStartDate,
              let end = transaction.domainLookupEndDate else { return nil }
        return end.timeIntervalSince(start)
    }
    
    /// Calculates TCP connection establishment duration
    /// Formula: connectEndDate - connectStartDate
    /// Represents: Time spent establishing TCP connection to server
    private static func calculateConnectDuration(from transaction: URLSessionTaskTransactionMetrics) -> TimeInterval? {
        guard let start = transaction.connectStartDate,
              let end = transaction.connectEndDate else { return nil }
        return end.timeIntervalSince(start)
    }
    
    /// Calculates TLS/SSL handshake duration
    /// Formula: secureConnectionEndDate - secureConnectionStartDate  
    /// Represents: Time spent performing TLS/SSL handshake for HTTPS connections
    private static func calculateSecureConnectionDuration(from transaction: URLSessionTaskTransactionMetrics) -> TimeInterval? {
        guard let start = transaction.secureConnectionStartDate,
              let end = transaction.secureConnectionEndDate else { return nil }
        return end.timeIntervalSince(start)
    }
    
    /// Calculates the image retrieval duration for a single transaction 
    /// Formula: responseEndDate - requestStartDate
    /// Represents: Time from sending HTTP request to receiving complete image response
    private static func calculateRetrieveImageDuration(from transaction: URLSessionTaskTransactionMetrics) -> TimeInterval? {
        guard let start = transaction.requestStartDate,
              let end = transaction.responseEndDate else { 
            return nil 
        }
        return end.timeIntervalSince(start)
    }
    
    /// Extracts HTTP status code from response
    /// Returns: HTTP status code (200, 404, etc.) or nil for non-HTTP responses
    private static func extractHTTPStatusCode(from transaction: URLSessionTaskTransactionMetrics) -> Int? {
        return (transaction.response as? HTTPURLResponse)?.statusCode
    }
}

// MARK: - Convenience Properties

extension NetworkMetrics {
    
    /// The download speed in bytes per second.
    ///
    /// Calculated as `responseBodyBytesReceived / retrieveImageDuration`. 
    /// Returns `nil` if the duration is unavailable or zero, or if no data was received.
    ///
    /// - Note: This uses the actual image retrieval duration, excluding redirects and other overhead,
    ///   to provide the most accurate representation of the data transfer rate.
    public var downloadSpeed: Double? {
        guard responseBodyBytesReceived > 0,
              let duration = retrieveImageDuration,
              duration > 0 else { return nil }
        
        return Double(responseBodyBytesReceived) / duration
    }
    
    /// The download speed in megabytes per second (MB/s).
    ///
    /// This is a convenience property that converts `downloadSpeed` from bytes per second 
    /// to megabytes per second for easier readability.
    ///
    /// - Returns: Download speed in MB/s, or `nil` if `downloadSpeed` is unavailable.
    public var downloadSpeedMBps: Double? {
        guard let speed = downloadSpeed else { return nil }
        return speed / (1024 * 1024)
    }
}
