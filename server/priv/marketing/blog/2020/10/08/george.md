---
title: "Interview with George Tsifrikas - What led us to modularize Workable's project was high build times"
category: "community"
tags: [Tuist, Workable]
excerpt: 'In this interview of apps at scale we interview George Tsifrikas, iOS team lead at Workable. He shares his experience growing their Xcode project into a modular app, how they use reactive programming extensively throughout the app, and the testing strategies that they follow to ship new features with confidence.'
interviewee_name: 'George Tsifrikas'
interviewee_role: "iOS team lead at Workable"
interviewee_x_handle: 'gtsifrikas'
type: interview
interviewee_avatar: https://pbs.twimg.com/profile_images/1201614336004898816/vI8KZmCr_400x400.jpg
---

In this new post of our "Apps at scale" series, we interview [George Tsifrikas](https://twitter.com/gtsifrikas), iOS team lead at Workable. George talks about their experience modularizing the Xcode project with CocoaPods to improve build-times and how that led them to build their own dependency injection framework, Inject. Moreover, he dives into their testing strategy and feature flags solution to allow teams to confidently deliver features. Without further ado, let's dive right into the interview.

## Team structure

### How are the teams structured?

The engineering teams at Workable are formed per a specific area in our product (video interviews, referrals, core.) except the mobile team. The mobile team is responsible for iOS and Android apps. It develops all the features that make sense to be on the mobile app and is not separated into feature squads.

### How many engineers work on features and how many take care of the infrastructure of your projects?

I hope to have a dedicated mobile infrastructure team sometime in the future, but we are not there yet. We are a small iOS team to get to do features and infrastructure for our app.

### How do designers and developers collaborate?

When we plan a new feature, our designer has a leeway of two weeks before implementing a feature. During that time, the mobile platform leads, and designers discuss how it could be implemented and any potential constraints. During the two weeks before the implementation, there is a lot of back and forth, mainly in the form of comments in [Figma](https://figma.com).

Upon starting the implementation of a feature, we may change a few things here and there. Maybe we couldn’t predict a use case but almost always stick to the design we started with. In the middle of the sprint, we do some catch-up between Android, iOS, and our designer to showcase our progress and align platform designs. Also, at that time, we correct some UI/UX issues that may come up. Generally, throughout the sprint, our designer receives staging builds, and she gives us feedback if we have missed something.

## Project

### What led you to modularize your app?

The one major thing was and mainly still is, compile times. As our project grew, so the compile times. Waiting 2 minutes for an incremental build and 8 minutes for a clean build was just painful, killing productivity.

### What did you learn during the process of modularizing the app?

It was a way more significant undertaking of an effort that we had in our minds when designing the modularisation. First, we did a lot of research on how the code should be separated. Not properly separating the code it may even increase the compile times of clean builds. Then, we tried to determine how we will support the modularisation effort in terms of the project's organization. We didn't want to create each module by hand each in a separate Xcode project because, for each module, we would have to pass all the build settings and how these are connected between them by hand, which would make the whole configuration tiresome and prone to errors.

We used [CocoaPods](https://cocoapods.org) with custom templates that we had declared our module once, and everything worked (almost). We had to change many build settings in the Podfile and do some other hacks to have [IBDesignable](https://nshipster.com/ibinspectable-ibdesignable/) to render in the storyboards. Right now, we are in the process of evaluating Tuist. When you start splitting your code, you want to do it incrementally, especially if it is a large codebase. So, we started from the Core module with swift extensions, networking, and almost everything shared between every feature. We tried to keep Core-like modules in small numbers, so right now, we have, `WorkableUIKit`, `UIComponents`, `Models`, `ModelsDecoding`, `Interfaces`, `Event` (our first feature module), and `Inject`.

### Have you developed any core module that you would like to share with the industry?

When you try to split code between modules to achieve fast build times, you need to reduce the interdependencies in code-level and module-level. For example, you have a shop app that shows a product listing, and you add the product to the cart and start the checkout process. Let's assume that the product listing functionality is implemented in the `Product` module and the checkout in the `Checkout` module. Ideally, you don't want the `Product` module to know anything about the `Checkout` module, not even its existence, except how to call it.

In our case, we have a dependency inversion layer that we have all the public protocols we want to share between our modules. In the previous example, the `Product` module can import `Interfaces` and use the `Checkout` module functionality, right? Almost, we need an instance for the concrete class inside the `Checkout` module that implements the protocol from Interfaces.

In our Workable app until then, we were doing dependency injection using constructors. Sometimes we weren't diligent or didn't pass the dependencies from the root _(AppDelegate)_. So, we needed a solution that is easy to use, and it didn't feel like a chore. So, we **created our own dependency injection library `Inject`**. `Inject` uses property wrappers to _"inject"_ properties anywhere you want by merely writing @Injected in front of the property.

### Can you tell us more about how you use property wrappers to do dependency injection?

Let's assume you have the following property in your code:

```swift
@Injected var fooInstance: Foo
```

Firstly, `Foo` must be a protocol. How Inject in our app finds the implementation of `Foo`? In our `AppDelegate` when the app starts we register to `Inject` all dependencies. But we found out that you will encounter two major issues when you do runtime registering and dependency resolving. The first one is that you may have dependency cycles without realizing it. Let's say we have `Foo` and `Bar` protocols with `FooImpl` and `BarImpl`. If you use in `FooImpl` an injected property of `Bar` and in `BarImpl` and injected property of `Foo` you will have a dependency cycle and while your app compiles, it will crash from stack overflow when it tries to use one of either of these classes. The solution for this was to create a little analyzer that uses `Swift`'s mirroring and does `DFS` throughout the dependency graph looking for cycles. If it finds one, it shows you the cycle to break it.

The second one was that you may again use the:

```swift
@Injected var fooInstance: Foo
```

and never registered how the `Foo` is initialized. Again the app will compile, but it will crash from `Inject`, saying that it didn't find a way to instantiate the `Foo` property. The solution for that is a little linter that runs from Xcode, like [SwiftLint](https://github.com/realm/SwiftLint). For example, it parses your codebase and finds out for each Injected property if it is registered. Suppose it finds out that one is not. In that case, it shows an Xcode error directly on the line for the unregistered dependency prompting you to register it. It really made it very enjoyable to use dependencies correctly and everywhere.

We hope to make it open source very, very soon!

## Code

### Could you briefly describe the architecture of your app and the paradigms that you follow?

We're big fans of reactive programming, and we're using [RxSwift](https://github.com/ReactiveX/RxSwift) from the start of the app. So all the data flows are done by observables. Each feature we write uses [RxMVVM](https://github.com/RossSong/RxMVVM), which enables us to write very comprehensive tests, especially for each screen's logic. For each feature, we have an entry point. For example, to compose a new email from the candidate screen all we have to do is, `emailComposer.new(forCandidate:) -> Observable<Void>` , note email composer is injected to the candidate screen. Also, we are using our own Swift Error handler to have uniform error handling across the app.

### How do you ensure consistency across the codebase (style, architecture)?

Nothing fancy here; we try to document everything we can, Swift style guide, Code architecture, How we test, and everything we can think of. Right now that we're hiring, it will prove very useful for our team's new members. We enforce the styling of the code with SwiftLint.

## Processes/Workflows

### How is the process since there’s an idea for a feature until it lands on the main branch (e.g. master)?

You can think of our apps as an extension of the Workable desktop app. When we decide to do a new feature, we decide which aspects make sense to be on mobile apps. Our mobile team leads and designer start working on the feature at least two weeks before its planned start date. After that, we start to do design meetings, and we start implementing the feature. Each work is closed to our main branch through a PR. It doesn't have to be complete, just not to break existing functionality. We try to keep small PRs so as not to spend much time reviewing significant changes. We can close PRs frequently because we use local feature flags. That means we can start a new feature behind a flag, and we ship unfinished work, but the end-user never gets to see that work. We use TestFlight to distribute staging builds to the designers and Product Managers through a custom pipeline created in Jenkins. As developers, we get frequent feedback, which lets us quickly fix things and iterate repeatedly. After we finish a feature, the PM responsible for this feature green-light it, and we ship it to the next release.

### How do you define feature flags? Do you use a service for that or is there an in-house solution?

The feature flags are just boolean values inside a plist file. We do not use them for A/B testing or remote launch of a feature. These are only for our convenience. It helps us avoid merging huge branches with many conflicts between each other, and each developer gets to work with the more "real" version of the code.

### When do you consider a feature “shippable”?

A feature is shippable when our designer has approved it and our PM. We have agreed on a timeline with other teams if there is an inter-dependency. Also, for essential features, a feature is shippable when we have fully end-to-end automated tests.

## Testing

### What’s your testing strategy?

We try to adhere to Martin Fowler's "the practical testing pyramid" as much as we can. For us, that means that we do a small number of end-to-end tests using Appium, which for our work and as integration tests. We try to have 80% coverage or more with unit tests and snapshot tests in each feature enforced by our CI pipelines on our PRs. Because our ETE tests are flaky sometimes and we need a lot of time to write them, we checked with our QA team and found out that almost all of our regressions are API related. That means that a response from the backend changed in a not agreed-upon way. So, we try to introduce another way of testing, which is called contract-testing using PACT. Our client and the backend have a contract that is validated in the unit tests of each platform. This type of testing is way quicker than running ETE tests, which take 3-4 hours. Our plan is to migrate less used features from the ETE suite to the contract suite to gain time and stability.

### Do you rely on third-party libraries for writing your tests?

- **ETE:** appium
- **Unit tests:** Quick
- **Snapshots:** nimble snapshot (works in cohort with Quick)
- **Contract tests:** PACT

### Do you have a QA team? If so, what’s their role?

We have a QA engineer who is responsible for both iOS & Android. The responsibilities are maintaining the test suite, CI/CD pipeline, and coordinating the release with other teams. The actual ETE tests are written by mobile engineers.

### What led you to write more snapshot and PACT tests?

For years we relied heavily on end-to-end tests. All this time, the app grew, and along with it, the ETE suite. This brought some problems with it. The suite now takes several hours to run. When you have multiple teams inside Workable who want to make their own releases, each team must wait for the ETE suite to pass to check that there are no regressions. As I mentioned above, we checked with our QA engineer and found out that many of the regressions that the ETE suite found were breaking API changes. We can use contract testing to cover this aspect of testing fast and stable as unit tests. Now, the suite caught some UI regressions, and we introduced snapshot testing in our feature development. This lets us check for any UI regression, and also it generates a visual diff if something breaks!

### How do you describe your PACT tests and when do you run them?

PACT tests are written in Swift. Essentially you describe the request to the backend and the expected result format. Then you verify in your test that you can parse that expected response. The contract is driven by the client. The backend is the consumer of that contract that must comply with. If any team wants to change an API that affects us, they have to contact the mobile team to schedule any necessary changes. Now the test runs in each commit in an open PR. We have a status page that shows the branch of the backend repo with the branch of iOS or Android and if the contact is verified in that configuration.

## Tooling

### What internal tools did you build that you are proud of?

The only internal tooling we have done so far for iOS was making CocoaPods the declaring modules mechanism. Making this work involved a lot of time learning about libraries, frameworks, dylib, etc. Not the best solution overall, but we may not have moved on with the modules without this.

### What are your main challenges on tooling when scaling?

The lack of proper tooling from Apple. We should have a more versatile solution for building and organizing our code. SPM is a step in the right direction, but it's still early.

### What are some challenges you are facing scaling up your project?

The biggest one I would say is consistency in the code. When the project gets quite big, people come and go it's difficult to communicate what has been implemented and where. For example, we may find the same Swift extension implemented multiple times with slightly different names. Documentation and anticipation of where to find something is essential.

## Last but not least

### If you started the project again, what would you do differently?

Focus more on code readability and organization. It is essential to have a certain way to do things initially but willing to change it if it doesn't fit requirements anymore.

### What are you the most excited about for WWDC?

From the software side, I really liked widgets and how they were implemented using SwiftUI to achieve such an excellent performance (serializing the SwiftUI on disk). From the hardware side, of course, Apple Silicon. I'm really excited about the future form factors and performance of hardware with Apple's own chip.

### How did COVID-19 impact your work style and processes?

Before COVID-19, almost all of our engineering was done on premises in our beautiful Athens offices. When the Greek government announced the lock-down, we were promptly forced to start working from home. We had one day per week that we could work from home until then, but this is totally different from remote working. We had to change the way we communicate, which translated to more documentation. Everything must have a place so anyone can find it easily, fewer meetings, and trying to have a more async way of communication.

### How do you favour asynchronous communication over synchronous one?

At first, anyone working from the office had the expectation of getting an answer to a question relatively quickly. When you migrate to the async way of communication, it is a little bit difficult because you have to wait or do something else if you are blocked by someone. Still, I believe this a small price to pay because you have the flexibility when to respond to someone, which is less distracting from the work you focused on right now. If someone answers you in Slack, you can go back later and see the answer again (but it probably should be documented somewhere).

### How do you make sure everyone is on the same page with a distributed team setup?

We use a knowledge base ([Confluence](https://www.atlassian.com/software/confluence)) for features or any research that we do in various ways. For technical stuff, we use markdown on GitHub. We're lucky our team is in the same timezone, and we have many overlapping hours between us, so later in the day, we do a catch-up meeting to get on the same page. Our goal is to eliminate that and use Trello or something similar to sync upon how we're doing.
