---
title: Tuist 1.7.1 - Edit all manifests, safer build settings API and SwiftUI projects
category: "product"
tags: [Tuist, release, swift, project generation, xcode, apple, '1.7.1']
excerpt: Easier manifests editing and safer configurations with Tuist 1.7.1
author: natanrolnik
---

Tuist's latest version, 1.7.1, has features developed by new contributors 👋🏻. Before joining me for an overview and
other significant changes in this version, bear in mind that version 1.7.0 was published
and we detected a critical bug due to a library incorrectly linked to the binary.
After the community identified the bug, [Pedro](https://www.github.com/pepicrft) quickly fixed the issue and
released 1.7.1. If you have issues with 1.7.0, you can
[read here](https://github.com/tuist/tuist/issues/1249#issuecomment-617275456) how to fix it.

## Edit All Manifests in One Single Project

If you worked with many Project.swift files across different projects, chances are high that you got tired of
changing directories and running `tuist edit`. Thanks to [Julian](https://github.com/julianalonso)'s
first contribution to Tuist, this is over. From now on, `tuist edit` will find recursively all `Project.swift`
files within your current directory and create an Xcode project with all of them.

## Syntactic Sugar API for Defining Build Settings

Another addition in this release is related to defining project and targets settings. Before this version, one would
define settings in the following way:

```swift
let baseSettings: [String: SettingValue] = [
  "ENABLE_BITCODE": "YES",
  "SWIFT_COMPILATION_MODE": "wholemodule",
]
```

This is not ideal. Having to repeat the strings manually and finding the possible values is not only tedious, but also
might lead to errors, since typos in strings are a common problem. Initially, I found myself using a few functions in
my [project description helpers](https://docs.old.tuist.io/guides/helpers/) to make the settings both type safety and to reduce duplication
of the strings. I raised the topic in the Tuist Slack group and adding these functions to `ProjectDescription` was a
welcome idea. This is exactly within the goals of Tuist: to make developers' life easier and the task of generating
projects less error prone. From now on, the code above can be written like this:

```swift
let baseSettings = SettingsDictionary()
    .bitcodeEnabled(true)
    .swiftCompilationMode(.wholemodule)
```

[Refer to the documentation](https://docs.old.tuist.io/manifests/project/#settingsdictionary) to see the list of built in
functions, and also to learn how you can add your own to your project description helpers. If you find yourself using a
function that others can leverage as well, don't hesitate to open a Pull Request adding them.

## Behind the Scenes and SwiftUI

Thanks to the efforts of [Marek](https://github.com/fortmarek) and [Daniel](https://github.com/mollyIV),
Tuist now uses [Apple's Swift Argument Parser](https://github.com/apple/swift-argument-parser) to parse the received
commands instead of SPM's parser (which will be eventually abandoned in favor of this new one).
The refactor done to adopt the new parser required Tuist to have a better separation of concerns,
so our code is even better now 💪.

Another contribution by Marek is the support for generating new SwiftUI-based project with the
[new `scaffold` command](https://docs.old.tuist.io/commands/scaffold/).

If you would like to see all the changes in this version, check them out in the
[release page](https://github.com/tuist/tuist/releases/tag/1.7.0).
