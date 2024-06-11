# Migrating from v5 to v6

Migrating Kingfisher from version 5 to version 6.

## Overview

Kingfisher 6.0 contains some breaking changes if you want to upgrade from the previous version. 

Depending on your use cases of Kingfisher 5.x, it may take no effort or at most several minutes to fix errors and warnings after upgrading. If you are not using Kingfisher with SwiftUI, and have no warnings in your code related to Kingfisher, then you are already done and feel free to upgrade to the latest version. Otherwise, please read the sections below before performing the upgrade.

### SwiftUI support

Kingfisher started to support SwiftUI from [5.8.0](https://github.com/onevcat/Kingfisher/releases/tag/5.8.0). At that time, a new framework was added to handle all SwiftUI-related things. Search for `KingfisherSwiftUI` in your SwiftUI code, or check if there is a `Kingfisher/SwiftUI` entry in your Podfile. If there is, then you need to perform some change of the integrating way before continuing.

In Kingfisher 6, to make the project structure simpler, as well as treat SwiftUI as the first citizen in the library, we combined the library for SwiftUI into the main Kingfisher target.

That means, there is no `KingfisherSwiftUI` or `Kingfisher/SwiftUI` anymore. If you installed it through:

- Carthage: Remove `KingfisherSwiftUI` from "Linked Frameworks and Libraries" and all "KingfisherSwiftUI.framework" related lines from the "copy-framework".
- CocoaPods: Remove `pod 'Kingfisher/SwiftUI'` from your Podfile. To continue using Kingfisher, you still need to keep or add back `pod 'Kingfisher'` entry. Then, run `pod install` again.
- Swift Package Manager: Since now there is only one framework, all the old "static" and "dynamic" variants are removed. We suggest a clean reinstallation for the new version. Check the [Installation Guide](https://github.com/onevcat/Kingfisher/wiki/Installation-Guide) for more.

When it is done, you can now replace any `import KingfisherSwiftUI` with `import Kingfisher`.

### Removing legacy deprecated code

All deprecated types, methods and properties are removed from the code base. Before upgrading, please make sure there is no warnings left in your project which complain the using of deprecated code. All deprecated things have replacement and with the help of warning message, adapting to new code should be easy enough.

If you are curious about what are exactly removed, check [these commits](https://github.com/onevcat/Kingfisher/pull/1525/files).
