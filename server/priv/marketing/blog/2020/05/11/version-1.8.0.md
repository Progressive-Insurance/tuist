---
title: Tuist 1.8.0 - Adding support for localized sources
category: "product"
tags: [Tuist, release, swift, project generation, xcode, apple, '1.8.0']
excerpt: In this blog post I talk about the Tuist verion 1.8.0 and the improvements that come with it. One of those is being able to define localized sources in the targets. Moreover, we changed the way we read the Swift version to always read it from the environment.
author: pepicrft
type: release
---

Hola 👋!

Despite our plan to release new versions every Friday,
we are doing things a bit different this time,
and we are releasing a new version on Monday.
In this blog post, I'm **introducing the version 1.8.0** of Tuist.

Unlike past releases that were packed with many features,
this is a tiny one with barely additions.
Nonetheless,
we are writing a blog post because we believe in the power of narrative as a means to convey the ideas behind it.

Let's dive right into what has changed in 1.8.0.

## Support for localized sources

[@Rag0n](https://github.com/Rag0n) added support for localized resources.
Thanks to it, you can now add localized files with the extension `.indentdefinition`.
Before this change,
we were treating the directories with extensions `.lproj`,
which Xcode uses go group localized resources and sources,
as a normal directory.

## Read the Swift version from the environment

There used to be a [few places](https://github.com/tuist/tuist/pull/1317) in the codebase where we used a hardcoded version of Swift.
To prevent it from causing issues when the hardcoded version doesn't match the system one,
we changed the implementation to always read the Swift version from the system.

## Community forum

It's been a while since we have it,
but it might have gone unnoticed for users of Tuist.
A while ago,
we created a [community forum](https://community.tuist.io) with the **aim of encouraging long and asynchronous discussions** and making them searchable and indexable by search engines like Google.
Slack,
the communication tool that we had been using since the inception of Tuist is great at real-time discussions but is not ideal when many important discussions are going on.

We'll continue using Slack, but we'll encourage people to use the forum for certain discussions.
We'll also continue using [GitHub issues](https://github.com/tuist/tuist/issues) to report bugs,
propose improvements and features, and share RFCs to get input from other contributors.

Here are some ongoing discussions worth checking out:

- [Ideas for Tuist](https://community.tuist.io/t/ideas-for-tuist/20/2)
- [An opinionated version of Tuist](https://community.tuist.io/t/an-opinionated-version-of-tuist/40)
- [Designing great experiences](https://community.tuist.io/t/designing-great-experiences/38)
- [Making schemes an implementation detail](https://community.tuist.io/t/making-schemes-an-implementation-detail/30)
- [List of deprecations for 2.0](https://community.tuist.io/t/list-of-deprecations-for-2-0/24)

## Some fixes

- Auto-generated `Info.plist` files for iOS apps no longer have the launch and main storyboards set - [#1289](https://github.com/tuist/tuist/pull/1289)
- Fixed a `scaffold` example in the documentation - [#1273](https://github.com/tuist/tuist/pull/1273)
- Fixed the `help` command that stopped working after a recent refactor - [#1250](https://github.com/tuist/tuist/pull/1250)

## What's next

There's an [ongoing work](https://github.com/tuist/tuist/pull/1186) to add support for signing to Tuist.
In a nutshell, Tuist will take care of installing certificates, copying profiles, and setting the right build settings to your projects.
All you need to do is to place them in the `Tuist/Signing` directory and use a built-in command to encrypt them.

Moreover, we paused the work on the cache to refactor one of our key pieces of the codebase, the [graph](https://github.com/tuist/tuist/blob/main/Sources/TuistCore/Graph/Graph.swift).
Since its creation,
the model has gone through several iterations and broadened its responsibilities.
We think it's now a good time to refactor it into a value type that will support well current and future features that we are planning for Tuist.

As always,
remember that you can update Tuist easily by running:

```bash
tuist update
```

Having said all of that,
I wish you all a great and safe week.
