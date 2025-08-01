---
title: Why Tuist?
category: learn
tags:
  [
    tuist,
    xcode project generation,
    xcode,
    swift,
    scale,
    ios,
    projects,
    scalability,
  ]
excerpt: In this blog post I share my thoughts on why I think Tuist is a good choice to scale up Xcode projects, and guide the reader through what I believe are key features to make that easy.
author: pepicrft
---

If you are considering the adoption of Tuist,
you might wonder _why_ a project like yours should make such a move.
The idea of adding a new tool to your toolbox might sound intimidating ―
it certainly is.
But believe me,
this is one that you won't regret about.
Despite having done our best to convey the idea behind Tuist,
and why it's an important piece when scaling up projects,
I feel we lacked a good summary.

## Make your projects consistent and conventional

After bootstrapping new projects and targets in Xcode,
it's up to the developers to ensure that projects are consistently configured and structured.
Some developers might see that as something great,
but that comes with some downsides:

- It adds **indirection** for developers when jumping between projects: _How is this project structured compared to this other?_ _Why is this target linking using build settings flags while the other one is using build phases?_
- Xcode's **indexing and build system** might not work as effectively because it needs to resolve configuration nuances across all the projects.
  Moreover, those nuances might be conflicting and result in compilation errors.

You might have seen teams solving this problem at the build settings level by extracting them into reusable [Xcode Build Configuration Files](https://nshipster.com/xcconfig/).
Still, we should not disregard that settings are just a piece of the cake ―
There are also build phases, targets, or schemes, for which Xcode doesn't provide any way to reuse them.
Other teams resort to scripts that run some checks on the projects,
but that results in a poor experience for developers because those checks are not built into their workflows.

Tuist solves this by providing [project description helpers](https://docs.old.tuist.io/guides/helpers/).
All you need to do is to define what types of projects are supported,
and codify them into functions that return templated projects:

```swift
import ProjectDescription

// Projects+Template.swift

extension Project {
  static func featureFramework(name: String) -> Project { /** Initialize project **/ }
  static func iOSApp(name: String) -> Project { /** Initialize project **/ }
}
```

That makes it possible to create a new feature framework that is consistent with the rest.
For instance,
I can create a new Search feature framework by creating a `Search` directory,
and placing the following `Project.swift` file in it:

```swift
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.featureFramework(name: "Search")
```

> Note how idiomatic and concise the definition of projects is ― your project is defined in one line.

## Dependencies

If there's something that bothered me when using Xcode daily,
it was how hard it becomes to **maintain a dependency graph**.
At some point,
you extract some logic into a transitive framework.
After following a very manual process,
other projects fail to compile.
You probably forgot to embed that framework into some products that have it as a transitive dependency.

I've talked to developers that think that it's developers' fault because they don't know how to do things in Xcode.
I'd counter-argue that when the dependency graph is large,
**there's so much they need to know to do things right**,
that the process becomes not just very manual,
but error-prone.
Having this mindset often leads to a terrible bus factor.
There's a person in the team that did the initial work of creating projects and frameworks,
and what's often considered _"the person that knows Xcode well"._

In Tuist,
we tasked ourselves with simplifying that until the point that **anyone could add/remove dependencies easily**.
We imagined how we'd like the user interface to be, and we built the rest from there:

```swift
public enum TargetDependency: Codable, Equatable {
  case target(name: String)
  case project(target: String, path: Path)
  case framework(path: Path)
  case library(path: Path, publicHeaders: Path, swiftModuleMap: Path?)
  case package(product: String)
  case sdk(name: String, status: SDKStatus)
  case cocoapods(path: Path)
  case xcFramework(path: Path)
}
```

When people compare Tuist to YAML-based project generators,
the **beauty of the dependencies API** pops in my mind.
My answer is always that it really depends on what you want for your projects.
If you want to move away from `.pbxproj` files and describe things in simpler YAML files using the same Xcode's concepts and ideas,
YAML-based project generation is your friend.
However, if you want to work with simpler concepts and ideas, and be more conventional, Tuist is your tool.
Our principle is that **simplicity and consistency are vital to scale up projects**.

Some well-known companies that adopted a YAML-approach for the generation of projects ended up building a tool on top of it.
While that's something large companies can do,
you might not want to find yourself in the situation where you need to build a tool yourself.
Moreover,
having tools on top of other tools adds indirections,
which in fact,
complicates optimization and debugging.

## Catch misconfiguration errors early

Xcode delegates catching errors to its build system.
The problem with that is that approach is that there are certain errors that the build system doesn’t know how to misconfigurations in the project. For example, if there’s a circular dependency, the compilation will fail with an error along the lines of: `“X not found”`. _What would you think as a developer?_ _Is it not found because I didn’t configure the right search paths?_ _Should I change the order in which targets are compiled in my scheme?_ The last thing you’d probably think is that there’s a circular dependency.

To prevent that, Tuist tries to catch errors as early as possible.
We know developers’ time is a precious asset,
and they should not spend it debugging Xcode errors unrelated to their changes.
We can’t catch everything, but we do our best.
Especially around the dependency graph.

Thanks to it, any developer can add a new framework to the dependency graph with the confidence that if they are doing something wrong, Tuist will catch it. Isn’t that great? Let me repeat that again: **anyone can modify the graph with confidence**. I can’t stress enough how great that is to grow your projects. If you make something wrong, you know that `tuist generate` will tell you.

In the entrepreneurial jargon, we'd say that we are **democratizing scaling up projects**.

## And more yet to come...

The benefit of having knowledge on your project is that we can provide streamlined workflows that leverage Apple's building blocks _(e.g. `xcodebuild`, `simctl`)_.
Here are some of the features that we are planning,
and that you'll be able to opt-in easily if you are already using Tuist:

- **Caching:** This is one of the features we are the most excited about building.
  Unlike build systems like [Buck](https://github.com/facebook/buck) or [Bazel](https://bazel.build/),
  which are mostly adopted by large companies that can invest in build systems and tooling,
  we are exploring adding caching at the module level.
  We'll generate projects where only the targets you plan to work on will be generated ―
  the rest will be pre-compiled frameworks and libraries that we'll pull from a remote cache.
- **Selective builds:** As projects get larger, building everything on CI is inefficient.
  For that reason, we'll combine [Git](https://git-scm.com/) information with your project's dependency graph to determine what needs to be built.
  In plain words, we'll build
- **Selective test runs:** Similar to the above, we'll provide a command to run only the tests that are impacted by your code changes. For that, we plan to use `xcodebuild` in combination with the `--only-testing` argument.
- **Run apps from the terminal:** As great as it sounds,
  you'll have a command,
  `tuist run`,
  to run any app in the selected destination _(e.g. iOS simulator)_.
  A good use case for this feature is trying out an example app from any of the frameworks of the project,
  without having to open Xcode.
- **Dynamic documentation:** A `tuist doc` command, inspired by [Cargo's doc command](https://doc.rust-lang.org/cargo/commands/cargo-doc.html), will generate dynamic documentation from the code that belongs to the project in the directory where the command is run from. Thanks to it, you will no longer have to depend on another tool, or add more configuration files.

## Some final words

At Tuist, we are aiming to help teams be **productive when working with projects of any scale**.

We are aware that not all the projects can have a tooling or infrastructure team,
and for that reason,
we are designing features optimizing for **zero configuration**.
Instead of having to depend on many tools to do your job _(e.g. project generators, [Fastlane](https://docs.fastlane.tools/), [Rake](https://github.com/ruby/rake), documentation generator)_,
you'll depend on just one that will make your projects the source of truth.

Unlike many developers,
we believe **that a large scale doesn't mean complexity.**
Therefore,
we are making a huge effort to not port complexity from Xcode over to Tuist.
Furthermore,
we are providing developers guidance on [our community forum](https://community.tuist.io) and [Slack group](https://slack.tuist.io),
to get rid of the accidental complexity that they have accumulated over the years.

If there's one important thing that I'd like you to take away from this blog post, that is: `large != complex`.
