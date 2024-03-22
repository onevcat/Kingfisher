//
//  AuthenticationChallengeResponsable.swift
//  Kingfisher
//
//  Created by Wei Wang on 2018/10/11.
//
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

@available(*, deprecated, message: "Typo. Use `AuthenticationChallengeResponsible` instead", renamed: "AuthenticationChallengeResponsible")
public typealias AuthenticationChallengeResponsable = AuthenticationChallengeResponsible

/// Protocol indicates that an authentication challenge could be handled.
public protocol AuthenticationChallengeResponsible: AnyObject {

    /// Called when a session level authentication challenge is received.
    ///
    /// This method provides a chance to handle and respond to the authentication challenge before the downloading can
    /// start.
    ///
    /// - Parameters:
    ///   - downloader: The downloader that receives this challenge.
    ///   - challenge: An object that contains the request for authentication.
    /// - Returns: The challenge disposition on how the challenge should be handled, and the credential if the
    /// disposition is `.useCredential`.
    ///
    /// > This method is a forward from `URLSessionDelegate.urlSession(_:didReceive:completionHandler:)`.
    /// > Please refer to the documentation of it in `URLSessionDelegate`.
    func downloader(
        _ downloader: ImageDownloader,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?)

    /// Called when a task level authentication challenge is received. 
    ///
    /// This method provides a chance to handle and respond to the authentication challenge before the downloading can
    /// start.
    ///
    /// - Parameters:
    ///   - downloader: The downloader that receives this challenge.
    ///   - task: The task whose request requires authentication.
    ///   - challenge: An object that contains the request for authentication.
    /// - Returns: The challenge disposition on how the challenge should be handled, and the credential if the
    /// disposition is `.useCredential`.
    ///
    /// > This method is a forward from `URLSessionDataDelegate.urlSession(_:dataTask:didReceive:completionHandler:)`.
    /// > Please refer to the documentation of it in `URLSessionDataDelegate`.
    func downloader(
        _ downloader: ImageDownloader,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?)
}

extension AuthenticationChallengeResponsible {

    public func downloader(
        _ downloader: ImageDownloader,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?)
    {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trustedHosts = downloader.trustedHosts, trustedHosts.contains(challenge.protectionSpace.host) {
                let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                return (.useCredential, credential)
            }
        }

        return (.performDefaultHandling, nil)
    }
    
    public func downloader(
        _ downloader: ImageDownloader,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        (.performDefaultHandling, nil)
    }

}
