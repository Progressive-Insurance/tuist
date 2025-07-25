---
title: Next for Tuist
category: "product"
tags: ['Tuist', '2021', 'vision']
excerpt: It's a wrap for 2020. In this blog post we share the vision of Tuist for 2021. We'll bring support for plugins, improve and standardize the integration of third party dependencies, add support for selective building and testing, and much more.
author: pepicrft
---

It’s almost a wrap for 2020. It’s been a year to explore new possibilities that Xcode project generation enables and provide teams with streamlined workflows to build great apps for Apple platforms.

In this blog post, I'll unfold the areas we’ll focus on in 2021.

## Plugins

With project generation, we gave teams a simple interface to describe their modular projects.
By design, we chose [Swift](https://developer.apple.com/swift/) as the language for describing them.
It was a great idea because it allowed us to provide a great developer experience and features like [project description helpers](https://docs.old.tuist.io/guides/helpers/).

As more projects adopted Tuist,
we realized it’d also be useful for teams to extract Tuist-related files into a different repository to make them organization-wide resources.
For example,
a company with templates defined in project description helpers could pull them into a separate repository,
and have access to them from multiple repositories.
This gave us the idea of introducing a new concept into Tuist, **Plugins**.

A plugin is a new form of encapsulation to reuse user-defined Tuist primitives across projects.
Plugins will have a companion manifest file, `Plugin.swift`, which defines the plugin configuration:

```swift
import ProjectDescription

let plugin = Plugin(
  projectDescriptionHelpers: true,
  templates: true
)
```

## Standard management of third-party dependencies

The integration between Tuist projects and the dependency managers is not ideal.
[Carthage](https://github.com/carthage) frameworks can be declared as framework dependencies.
Still, the project generation might fail if developers forget to run the right Carthage command to fetch them.
When projects depend on [CocoaPods](https://cocoapods.org),
Tuist runs `pod install` after generating the project but can’t validate that the integration described in the `Podfile` is right.
That might result in projects that are seemingly right but that don’t compile.

Finally,
Swift Package Manager is integrated at build time by leveraging Xcode’s integration with the Swift Package Manager.
That leads to a terrible developer experience because Xcode tries to resolve them at launch time.
If it fails,
the project is left in an unusable state.
Moreover,
packages that declare their products are static might lead to upstream duplicated symbol issues.

We are very well-aware of this problem and therefore would like to do something from our side to provide a better developer experience integrating their third-party dependencies.
We believe a great developer experience revolves around a **standard interface** across dependency managers.
We'll achieve that by extracting the **dependency graph resolution** from the generation and launching of the project,
and **integrating** the third-party dependencies graph with the local graph.

## Selective building and testing

In large projects,
building and testing all the project targets in [continous integration (CI)](https://en.wikipedia.org/wiki/Continuous_integration) is inefficient;
only the targets that are impacted by the changes should be tested and built.
The common scenario that we find in large projects is a developer opening a tiny pull request, and having to wait half an hour to get all the green checks before merging.

Since Tuist knows about the project dependency graph, and the changed files by using the underlying a version control tool (e.g. git),
it can combine that information with some other heuristics to provide selective building and testing and speed up developers' workflows.

By letting Tuist optimize the workflows, teams will automatically get optimizations introduced in future releases. Furthermore, they can focus their efforts on building the apps and not defining an efficient CI workflow.

## Caching improvements

In 2020 we introduced the concept of generating **focused projects**. Focused projects are projects optimized to work on a given target. For example, if I plan to work on app `MyApp` and the framework `MyAppSupport`, I can run `tuist focus MyApp MyAppSupport`, and Tuist will remove the targets that are not necessary to work on those targets, and replace direct and transitive dependencies with a precompiled versions of them. The latter is something that we refer to as **caching**.

Unlike modern build systems like [Buck](https://buck.build) and [Bazel](https://bazel.build) that cache at the file level at the cost of taking developers away from Xcode's build system and having to keep up with Xcode updates, Tuist's caching works at the module level and using Xcode's build system. It provides a command, `tuist cache warm`, to precompile and cache every project's cacheable target.

Caching works great with some ideal project scenarios. However, there are many complex project scenarios that we don't handle gracefully. For example, the caching of projects with transitive Swift Packages as dependencies doesn't work. It's not impossible, but it'll certainly require a fair amount of work. We are aligning our work on better management of third-party dependencies to allow their caching. By the end of 2021, we hope to cache most of the target types: _frameworks, libraries, bundles, and third-party dependencies._

## App releasing

Releasing an app involves many steps: bumping the app version, archiving the app, exporting it with the right signing profiles, and uploading it to Testflight. Tuist could streamline all of them into a single workflow that gets triggered by running:

```
tuist release
```

The command would work both locally and on CI, signing the app with the right provisioning profile and certificate, and authenticating and uploading the app through the [App Store Connect API](https://developer.apple.com/app-store-connect/api/).

## Tuist 2.0

Tuist's API has been very stable for the last few years, and we have a good amount of features to justify the release of a new major version. Therefore, 2021 will be the year when we'll release a new major version of Tuist, 2.0. To make this new release special, we are working on a **redesign of our brand and website**. We are taking the opportunity to revisit the website's content to ensure the ideas are clearly conveyed and that users can find what they are looking for easily.

## Closing words

Tuist was born in 2016 out of the necessity for a tool to describe Xcode projects of any size using plain language. We built it upon a **dependency graph** representation, which enabled useful features such as project linting, workspaces, and the generation of focused projects. We chose Swift as a language because it felt natural to developers and allowed us to provide a great developer experience; developers could edit their projects using the editor and the programming language they were most familiar with. Moreover, they'd get documentation, validation, auto-completion, and syntax-highlighting without having to leave Xcode.

The natural next step to project generation was **automation**. For years the industry had settled on the idea of programming workflows using a programmable DSL like [Fastlane](https://github.com/fastlane), which acted like a glue between the terminal and the Xcode projects. However, with Tuist understanding your projects, Fastlane seemed an unnecessary layer of indirection. We could provide a streamlined experience through a standard set of commands that developers could familiarize themselves with. Like it happens with the Swift Package Manager, developers could use the same commands in any directory that contained a `Project.swift` or a `Workspace.swift`. **Build and test** were born.

Fast forward to today, we are focusing our efforts around **caching** because we know it's the challenge many projects struggle a lot with. Neither replacing their build system nor spinning an infrastructure team is an option for most of them. We want to be there with those users and support them to scale up their projects.

**What comes after 2021?** It's hard to say, but I can assure you that we'll work hard to make developer experience and productivity independent from the projects' size.

Happy end of 2020 🤗
