# 更新 Change Log

## 概述

- 提取代码库变更
- 确定下一个版本号
- 更新 pre-change 文件，该文件会被 release 脚本使用。

## 详细

- 目标文件：pre-change.yml
- 文件格式：

    ```yaml
    version: 目标版本号
    name: 版本名字
    add:
    - add content 1 [#{PR_NUMBER}]({LINK_OF_PR_NUMBER}) @{AUTHOR_OR_REPORTER_NAME}
    - add content 2
    fix:
    - fix content 1
    - fix content 2
    ```

    一个 sample：

    ```yaml
    version: 8.3.2
    name: Tariffisher
    fix:
    - Memory cache cleanning timer will now be correctly set when the cache configuration is set. [#2376](https://github.com/onevcat/Kingfisher/issues/2376) @erincolkan
    - Add `BUILD_LIBRARY_FOR_DISTRIBUTION` flag to podspec file. Now CocoaPods build can produce stabible module. [#2372](https://github.com/onevcat/Kingfisher/issues/2372) @gquattromani
    - Refactoring on cache file name method in `DiskStorage`. [#2374](https://github.com/onevcat/Kingfisher/issues/2374) @NeoSelf1
    ```

- 任务步骤

1. 读取变更和相关人员
    - 读取当前 master branch 和上一个 tag （release）之间的变更
    - 提取变化内容和相关的 GitHub PR/Issue和相关人员
    - 如果 PR 是对某个 issue 的修复，那么除了 PR 作者之外，issue 报告者也是相关人员
    - 一个变更可以有多个相关人员
2. 根据变化，按照 Semantic Versioning 的规则，确定版本号
3. 为版本拟定一个短语（三个单词以内），作为版本名字。最好有趣一些，与当前版本的核心变化相关
4. 更新 pre-change.yml 文件