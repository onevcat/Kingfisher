//
//  AssociatedObjects.swift
//  Kingfisher
//
//  Created by João D. Moreira on 31/08/16.
//  Copyright © 2016 Wei Wang. All rights reserved.
//

import ObjectiveC

/**
 *	This file provides a wrapper around Objective-C runtime associated objects.
 *  All values are wrapped in an instance of Wrapper allowing us to persist Swift value types.
 */
private final class Wrapper<T> {
    let value: T
    init(_ x: T) {
        value = x
    }
}

private func wrap<T>(x: T) -> Wrapper<T> {
    return Wrapper(x)
}

func setAssociatedObject<T>(object: AnyObject, value: T, associativeKey: UnsafePointer<Void>, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
    if let v: AnyObject = value as? AnyObject {
        objc_setAssociatedObject(object, associativeKey, v, policy)
    } else {
        objc_setAssociatedObject(object, associativeKey, wrap(value), policy)
    }
}

func getAssociatedObject<T>(object: AnyObject, associativeKey: UnsafePointer<Void>) -> T? {

    let v = objc_getAssociatedObject(object, associativeKey)

    if let v = v as? T {
        return v
    } else if let v = v as? Wrapper<T> {
        return v.value
    } else {
        return nil
    }
}
