---
title: Local caching of frameworks with Tuist 1.13.0 Bella Vita
category: "product"
tags:
  [
    Tuist,
    release,
    swift,
    project generation,
    xcode,
    apple,
    '1.13.0',
    'fastlane',
    'automation',
    'bazel',
    'fast builds',
  ]
excerpt: In this blog post we introduce Tuist 1.13.0 Bella Vita. It's is a huge leap forward for Tuist because it introduces a new feature, local cache, to help teams speed up their buidls. This version also ships with significant improvements and some bug fixes.
author: pepicrft
---

It's been quiet and productive weeks for Tuist.
We silently shipped a new version, Tuist 1.12.0,
and just yesterday,
we shipped the version 1.13.0,
which we called **Bella Vita**.

In this blog post,
I'll tell you about major features that we shipped in these two releases,
as well as minor improvements and bug fixes that continue to improve the stability and the performance of the tool.
Let's dive right in.

## Local caching

As you might know,
as projects get larger, one of the challenges teams often face is slow builds.
Xcode has an incremental build system that tries to reuse results from past compilations to make builds faster.
The problem though is that developers are used to using **CMD+K** when the compilation on Xcode yields errors.
That invalidates Xcode's cache and results in a clean build.

Some projects minimize the build time of clean builds by having a more horizontal project architecture _(e.g., [µFeatures architecture](https://docs.old.tuist.io/building-at-scale/microfeatures/))_. Large companies prefer to replace Xcode's build system with other build systems like [Bazel](https://bazel.build) or [Buck](https://buck.build/) that the output of individual build steps remotely. Unfortunately, the latter is a huge undertaking that is not feasible for small and medium companies.

In Tuist, we aim to help teams with the challenges they face when scaling up projects, which was an obvious one to tackle.

Tuist 1.13.0 ships with a new feature, **cache**, which allows generating projects replacing dependencies with their pre-compiled version. To use this feature, developers can use the following 2 commands.

```swift
tuist cache warm
tuist focus --cache
```

When we **warm the cache**, we build all frameworks as xcframeworks and store them in a local directory. They are uniquely identified by a hash that is calculated based on the target attributes, project, dependencies, and the environment (e.g. Tuist and Swift version). Developers can run `tuist cache warm` locally after cloning the project or changing between branches. In the future, projects will be able to run that from CI, and Tuist will be able to pull them from cloud storage (this is already being worked on).

After warming the cache, developers can run `tuist focus --cache` which reads as: _I want to focus on the project in this directory, please, replace the dependencies (if possible) with their xcframework from the cache_. For instance, if you plan to work on `MyApp`, all the direct and transitive dependencies that `MyApp` depends on will be xcframeworks. That means even if you use CMD+K, you'll always be compiling just `MyApp`.

**If you want to know more about the feature**, you can read our page [**Caching dependencies**](https://docs.old.tuist.io/building-at-scale/caching/) in the documentation.

## Minor improvements

#### Clean

Some Tuist features use a local cache to have a better performance. Until this version, the only way to clean the cache was by deleting the `~/.tuist/Chache` manually. Fortunately, that's not necessary anymore because developers can now run [`tuis clean`](https://github.com/tuist/tuist/pull/1516).

#### Secret

Tuist's signing management requires a secret key under the `Tuist` directory that is used for encrypting and decrypting the certificates. To generate cryptographically secured key, there's now a new command [`tuist secret`](https://github.com/tuist/tuist/pull/1471) that generates and outputs a random key.

#### Invalid globs

Unlike Xcode projects, with Tuist developers can use glob patterns such as `Sources/**/*.swift` to specify a group of files.
When a glob pattern pointed to a non-existing directory, it resulted in an empty group of files, and developers wondering why files were missing.
We changed that by [adding a check](https://github.com/tuist/tuist/pull/1523) that verifies if the pattern is valid. Now if developers use an invalid pattern, the generation of projects will fail and tell them why.

#### Upward search for the Setup.swift file

`tuist up` only worked when the directory where it was run from contained a `Setup.swift`.
From this version, we [changed the behavior](https://github.com/tuist/tuist/pull/1513) to do an upwards lookup. For example, given the following scenario:

```bash
/Setup.swift
/Projects
  /App
    Project.swift
```

Running `tuist up` under `Projects/App` would use the root `Setup.swift`.

#### Edit projects with the select Xcode project

`tuist edit` ignored the selected Xcode version when opening the project for editing the manifests. That's [fixed now](https://github.com/tuist/tuist/pull/1511). `tuist edit` will read the selected Xcode version and use that one instead.

#### Generate a graph without test targets and external dependencies

`tuist graph` has now [support](https://github.com/tuist/tuist/pull/1540) for not including test targets and external dependencies in the generated graph:

```bash
tuist graph --skip-test-targets --skip-external-dependencies
```

## Bug fixes

#### Set Core Data models as sources

There was a bug in the generation logic that added Core Data models as resources instead of sources. With [this fix](https://github.com/tuist/tuist/pull/1542) they are now added as sources (as Xcode expects them).

#### Encoding of Swift packages

[There was a bug](https://github.com/tuist/tuist/pull/1558) in the logic that encodes/decodes the definition of a Package dependency that broke the generation of projects when the package requirement was a revision. That's fixed now.

#### Use Homebrew which

`tuist up` failed to detect is a Homebrew formula was installed when the name of the formula didn't match the executable name. As [described in this PR](https://github.com/tuist/tuist/pull/1544), we are now using Homebrew's list command.

#### Auto-generated schemes for extensions

We have [fixed](https://github.com/tuist/tuist/pull/1545) a bug that caused the auto-generated schemes for extensions to fail at launching them.
