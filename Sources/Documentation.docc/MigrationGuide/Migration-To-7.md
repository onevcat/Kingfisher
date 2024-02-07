# Migrating from v6 to v7

Migrating Kingfisher from version 6 to version 7.

## Overview

Kingfisher 7.0 contains some breaking changes if you want to upgrade from the previous version. In this documentation, we will cover most of the noticeable API changes.

### Deploy target

The UIKit/AppKit part of Kingfisher now supports from:

- iOS 12.0
- macOS 10.14
- tvOS 12.0
- watchOS 5.0

> We do not have proper simulator support or device of versions before those. So dropping any older versions give us a chance to make sure the project works properly on all supported versions. This also fixes a compiling issue when building with Xcode 13 with SPM.

The SwiftUI part of Kingfisher now supports from 

- iOS 14
- macOS 11.0
- tvOS 14.0
- watchOS 7.0

> On iOS 13, there is no `@StateObject` property wrapper, which makes it very tricky when loading data properly across difference view body evaluating. For a stable data model in Kingfisher's SwiftUI, we need to drop iOS 13 and all other platform versions from the same year.

### Migration Steps

The main breaking changes happens to the SwiftUI support. By following the steps you should be able to migrate to the new version.

- Make sure you do not have any warning from Kingfisher. All previous deprecated methods and properties are removed in version 7. If you are still using some of the deprecated methods, follow the help message to fix them first before migrating.
- The original ``KFImage`` initializers: `init(source:isLoaded:)` and `init(_:isLoaded:)` are removed. Or strictly speaking, the `isLoaded` parameter is removed. If you are not using the `isLoaded` binding before, the transition to the new initializer ``KFImage/init(source:)`` and ``KFImage/init(_:)`` is transparent.
    - The `isLoaded` binding was a mis-use of binding and it did not do what is expected. If you need to get a state of loading of a ``KFImage``, change a `@State` yourself in the related ``KFImage`` lifecycle modifier: such as ``KFImage/onSuccess(_:)`` and ``KFImage/onFailure(_:)``.
    - All of the `isLoaded` parameter are also removed from the chain-able ``KF`` shorthand.
- If you are using ``KFImage/loadImmediately(_:)`` to get workaround of [#1660](https://github.com/onevcat/Kingfisher/issues/1660), it is not necessary in the new version anymore. You will have a warning and please just remove it.
