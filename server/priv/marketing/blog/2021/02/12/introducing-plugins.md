---
title: Introducing plugins
category: "product"
tags: ['Tuist', 'Plugins', 'Xcode', 'Swift']
excerpt: Plugins is a new feature that allows reusing Tuist building blocks across repositories. In this blog post we present the feature and how teams can leverage it to share project description helpers.
author: pepicrft
---

Building Tuist has taught us that there's **an opportunity to share elements of your projects across repositories**.
Let's say you work in an agency with projects scattered across several repositories.
In that scenario,
you might want your projects to be consistently structured to remove the cognitive load when jumping between projects.
That was not possible in Tuist.
The manifest files were tied to a repository.
Some projects tried to solve it by resorting to git submodules and cloning other repositories in specific directories to be seen by Tuist as local directories.
However, that was a workaround and not a proper solution.

As a tool that helps teams with their challenges, it was a natural next step to allow teams to extract some Tuist elements into a separate repository and reuse them easily. The idea of building plugins was born.

## Plugin.swift

A plugin is represented by a repository containing a `Plugin.swift` file and all the files that are part of the plugin. The current format of the manifest is simple, but we’ll continue to extend it as we add support for sharing more pieces:

```swift
import ProjectDescription

let plugin = Plugin(name: "MyPlugin")
```

This first implementation of plugins only supports reusing helpers.
Those are defined under `ProjectDescriptionHelpers` like in the example below:

```bash
.
├── ...
├── Plugin.swift
├── ProjectDescriptionHelpers
└── ...
```

## Using a plugin

Then users can declare the plugins in their projects' `Config.swift` file. They can indicate if they'd like the plugin to be read from a local directory or a remote repository *(commit or tag)*.

```swift
import ProjectDescription
let config = Config(
    plugins: [
        .local(path: "/Plugins/MyPlugin"),
        .git(url: "https://url/to/plugin.git", tag: "1.0.0"),
        .git(url: "https://url/to/plugin.git", sha: "e34c5ba")
    ]
)
```

As easy as that. Then you should be able to use the helpers from the plugin in your project by simply importing the plugin:

```swift
import ProjectDescription

import MyTuistPlugin
let project = Project.app(name: "MyCoolApp", platform: .iOS)
```

## What's next

Plugins are a powerful feature that opens the door to sharing content from your project with your organization's projects and the industry. Imagine coming up with a project architecture that you think is neat, and you'd like to share it publicly. Companies used to do that through blog posts, but now, you can codify it into project description helpers and share them in a plugin 🤯.

Moreover, we are planning to open a new interface for users to provide **project transformations** (mappers) that are applied at generation time. Once we have them available, we'll extend the plugins to support reusing them too.

[Unlike the Swift Package Manager](https://ppinera.es/2021/02/05/tuist-and-spm/), we can be there right where our users need us. Listening to them and providing the features that they need to scale up their projects. If you are using Tuist, we encourage you to give plugins a shot and share thoughts and ideas in our [community forum](https://github.com/tuist/tuist/discussions). Thanks for reading.
