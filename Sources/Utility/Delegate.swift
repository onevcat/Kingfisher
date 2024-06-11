//
//  Delegate.swift
//  Kingfisher
//
//  Created by onevcat on 2018/10/10.
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

/// A class that maintains a weak reference to `self` when implementing `onXXX` behaviors.
/// Instead of manually ensuring that `self` is kept as weak in a stored closure:
///
/// ```swift
/// // MyClass.swift
/// var onDone: (() -> Void)?
/// func done() {
///     onDone?()
/// }
///
/// // ViewController.swift
/// var obj: MyClass?
///
/// func doSomething() {
///     obj = MyClass()
///     obj!.onDone = { [weak self] in
///         self?.reportDone()
///     }
/// }
/// ```
///
/// You can create a `Delegate` and observe it on `self`. This ensures there is no retain cycle:
///
/// ```swift
/// // MyClass.swift
/// let onDone = Delegate<(), Void>()
/// func done() {
///     onDone.call()
/// }
///
/// // ViewController.swift
/// var obj: MyClass?
/// 
/// func doSomething() {
///     obj = MyClass()
///     obj!.onDone.delegate(on: self) { (self, _) in
///         // The `self` here is shadowed and does not retain a strong reference.
///         // Thus, both the `MyClass` instance and the `ViewController` instance can be released.
///         self.reportDone()
///     }
/// }
///
public class Delegate<Input, Output>: @unchecked Sendable {
    public init() {}

    private let propertyQueue = DispatchQueue(label: "com.onevcat.Kingfisher.DelegateQueue")
    
    private var _block: ((Input) -> Output?)?
    private var block: ((Input) -> Output?)? {
        get { propertyQueue.sync { _block } }
        set { propertyQueue.sync { _block = newValue } }
    }
    
    private var _asyncBlock: ((Input) async -> Output?)?
    private var asyncBlock: ((Input) async -> Output?)? {
        get { propertyQueue.sync { _asyncBlock } }
        set { propertyQueue.sync { _asyncBlock = newValue } }
    }
    
    public func delegate<T: AnyObject>(on target: T, block: ((T, Input) -> Output)?) {
        self.block = { [weak target] input in
            guard let target = target else { return nil }
            return block?(target, input)
        }
    }
    
    public func delegate<T: AnyObject>(on target: T, block: ((T, Input) async -> Output)?) {
        self.asyncBlock = { [weak target] input in
            guard let target = target else { return nil }
            return await block?(target, input)
        }
    }

    public func call(_ input: Input) -> Output? {
        return block?(input)
    }

    public func callAsFunction(_ input: Input) -> Output? {
        return call(input)
    }
    
    public func callAsync(_ input: Input) async -> Output? {
        return await asyncBlock?(input)
    }
    
    public var isSet: Bool {
        block != nil || asyncBlock != nil
    }
}

extension Delegate where Input == Void {
    public func call() -> Output? {
        return call(())
    }

    public func callAsFunction() -> Output? {
        return call()
    }
}

extension Delegate where Input == Void, Output: OptionalProtocol {
    public func call() -> Output {
        return call(())
    }

    public func callAsFunction() -> Output {
        return call()
    }
}

extension Delegate where Output: OptionalProtocol {
    public func call(_ input: Input) -> Output {
        if let result = block?(input) {
            return result
        } else {
            return Output._createNil
        }
    }

    public func callAsFunction(_ input: Input) -> Output {
        return call(input)
    }
}

public protocol OptionalProtocol {
    static var _createNil: Self { get }
}
extension Optional : OptionalProtocol {
    public static var _createNil: Optional<Wrapped> {
         return nil
    }
}
