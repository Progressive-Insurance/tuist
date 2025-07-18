---
title: Tuist 1.3.0 - Performance improvements and generation of projects while editing
category: "product"
tags: [tuist, release, swift, xcode, project generation, xcodeproj]
excerpt: The newest release brings you many bugfixes and improvements. However with the number of contributors steadily growing the team has also been busy thinking and writing about the direction of Tuist. We have a rough plan for Tuist 2.0 and work has started on compiling a manifesto to explain a bit more about the goals and values of the project.
author: pepicrft
---

Tuist 1.3.0 has just [been published](https://github.com/tuist/tuist/releases/tag/1.3.0).
In this blog post,
I'll walk you through the improvements and fixes that we shipped in this release,
and hint what are the upcoming features that we plan to work on.

## Generate the projects when editing the project in Xcode

Tuist has a command,
`tuist edit`,
which creates an Xcode project to edit your project manifest files.
The benefit of that is that developers can get inline documentation and validate the syntax by just building the manifest in Xcode.
We know this feature is quite handy,
so [we improved](https://github.com/tuist/tuist/pull/958) it by adding support for running `tuist generate` directly from Xcode.
The editable Xcode project will have an extra scheme that runs the generation command.
That way users don't have to go back to the terminal and run `tuist generate` manually.

## Preserve user data when generating the projects

Xcode projects have files of type `.xcuserdata` that Xcode generates with user-specific configuration.
Those files are deleted when projects are generated with `tuist generate`.
Thanks to [this work](https://github.com/tuist/tuist/pull/1006) that's not the case anymore.
From Tuist 1.3.0,
`tuist generate` generates the projects preserving that data.

## Performance-related improvements

The generation of Xcode project **needs to be fast.**
Unfortunately, the performance of the generation logic is something that we have disregarded since the inception of the project, and now some users are hitting slow project generations.
We decided it's time to tackle this so the first step that we took was adding a [helper utility](https://github.com/tuist/tuist/pull/957) that helps us benchmark the performance.
Thanks to it,
we'll be able to uncover performance bottlenecks and fail pull requests if we introduce regressions.

Moreover, we made [some improvements](https://github.com/tuist/tuist/pull/980) in the logic that sorts the project groups and files getting an improvement of roughly 50%.

## Project manifesto

As the project grows,
it's crucial for users, contributors, and maintainers to know what are our design pillars.
For that reason,
we updated our documentation to include a [manifesto](https://docs.old.tuist.io/contributors/manifesto/) that contains a set of principles that are foundational to the design and development of Tuist.
They help align users and contributors with the vision of the project.

## Installation from Google Cloud Storage

Tuist used to install new versions of Tuist by pulling the binaries from the GitHub releases.
As users reported, that caused some issues because GitHub's API returned limit errors.
To mitigate this issue,
we moved our artifacts to Google Cloud Storage.
Moreover,
we took the opportunity to add support for pulling binaries for incremental builds.
For instance,
if a developer wants to try out a specific commit,
they can run `tuist local commit_sha` and Tuist will pull the binaries and make sure that we are running the right version.

## Other fixes and improvements

Tuist 1.3.0 also ships with minor fixes and improvements that are worth mentioning:

- Added metal as a valid source extension - [Link](https://github.com/tuist/tuist/pull/1023)
- Fixed false positive warnings during the linting process - [Link](https://github.com/tuist/tuist/pull/981)
- Added support for target action paths without the `./` prefix - [Link](https://github.com/tuist/tuist/pull/997)
- Ensured bcsymbolmap paths are consistently sorted
- Updated XcodeProj to 7.8.0
- Added "Base" to the list of known regions - [Link](https://github.com/tuist/tuist/pull/1021)

## What’s next

Our goal is to provide teams with a full-fledged tool that helps them deal with their projects at scale. The list of challenges that teams face when scaling up their projects is long:

- Keep consistency across projects.
- Ensure that projects are simple and that can be modularized easily.
- Seamless management of certificates and profiles.
- Have insights about build times and the quality of the project.
- Slow build times.

We are starting to take the steps towards helping teams with those challenges. In fact, we are implementing a simple and standard interface to build and test projects. With it, projects no longer need another layer _(e.g. Fastfiles)_ that can become complex and hard to reason about. If you are in a directory where there’s a Project.swift or a Workspace.swift, you’ll be able to run `tuist build` and `tuist test`.

Moreover, we are implementing caching by leveraging [xcframeworks](https://developer.apple.com/videos/play/wwdc2019/416/) and project generation. Teams might need to simplify their projects and remove side effects, for example, introduced by script build phases, but the benefits are huge. The only source code that developers will need to compile is the code of the module that they are working on. Transitive and non-transitive dependencies will be xcframeworks.

> In other words, we are making scaling Xcode projects easy and fun for the rest of us

It’s an ambitious plan but we are confident we can get there. We can’t move as fast as we’d like to but this slow yet steady pace is helping us keep an eye on the architecture and ensuring it evolves sustainably with the project. If you’d like to be part of the journey and contribute to making it happen join our [Slack](https://slack.tuist.io) and let us know. We’ll gladly onboard you and give you pointers to start contributing.
