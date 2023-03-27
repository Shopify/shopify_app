# Contributing to the Shopify App gem

The following is a set of guidelines for contributing to the Shopify App gem. These are mostly guidelines, not rules. Use your best judgement, and feel free to propose changes to this document in a pull request.

#### Table of contents

[I just have a question!](#i-just-have-a-question)

[How can I contribute?](#how-can-i-contribute)
  * [Reporting bugs](#reporting-bugs)
  * [Suggesting or requesting improvements](#suggesting-or-requesting-improvements)
  * [Pull requests](#pull-requests)

## I just have a question!

> **Note:** Please don't file an issue to ask a question. You'll get faster results by using the resources below.

Shopify has an official message board with dedicated forums to discuss all things apps, APIs, SDKs and more.

#### Shopify Community forum links

* [Shopify Community](https://community.shopify.com)
* [Shopify Apps](https://community.shopify.com/c/Shopify-Apps/bd-p/shopify-apps)
* [Shopify APIs & SDKs](https://community.shopify.com/c/Shopify-APIs-SDKs/bd-p/shopify-apis-and-technology)

If you prefer to chat instead, join the [Shopify Partners Slack Community group](https://www.shopify.com/partners/community#conversation). This Slack group hosts an active community of thousands of app developers.

By participating in the Community forum or Slack group, you agree to adhere to the forum [Code of Conduct](https://community.shopify.com/c/Announcements/Code-of-Conduct/m-p/491969#M23) outlined.

## How can I contribute?

### Reporting bugs

This section guides you through submitting a bug report for the Shopify App gem. Following these guidelines helps maintainers and the community understand your report, reproduce the behavior, and find related reports.

#### Before submitting a bug report

* **Check the [troubleshooting guide](/docs/Troubleshooting.md).** You may be able to troubleshoot the issue you're facing.
* **Check the [Shopify Community links](#shopify-community-forum-links) to search for your issue.** This problem may have been reported before and solved on the Shopify forum.
* **Perform a cursory search for similar issues.** You may find that the same problem (or a similar one) has been filed already as an issue.

#### How do I submit a good bug report?

Bugs are tracked as GitHub issues. Create an issue and provide the following information by filling in the [bug-report template](/.github/ISSUE_TEMPLATE/bug-report.md).

Explain the problem and include additional details to help maintainers reproduce the problem:

* **Use a clear and descriptive title** for the issue to identify the problem.
* **Describe the exact steps which reproduce the problem** in as many details as possible.
* **Provide specific examples to demonstrate the steps.** Include links to files, or copy/pasteable snippets. If you're providing snippets in the issue, use Markdown code blocks.
* **Describe the behavior you observed** after following the steps and point out what exactly is the problem with that behavior.
* **Explain which behavior you expected to see** instead and why.
* **Include screenshots and animated GIFs** where possible.
* **Redact any private information** from your logs and issue description. This includes things like API keys, API secrets, and any access tokens.

### Suggesting or requesting improvements

If you have a suggestion for the Shopify App gem or a feature request, provide the appropriate information by filling out the [feature-request template](/.github/ISSUE_TEMPLATE/feature-request.md).

### Pull requests

The process described here has several goals:

* Maintain the Shopify App gem's quality (does the change you're making have a test?)
* Fix problems that are important to app developers
* Enable a sustainable system for the Shopify App gem's maintainers to review contributions

Please follow these steps to have your contribution considered by the maintainers:

* Follow all instructions in the [pull request template](/.github/PULL_REQUEST_TEMPLATE.md)
* After you submit your pull request, verify that all status checks are passing
  * <details>
      <summary>What if the status checks are failing?</summary>

      While the prerequisites above must be satisfied prior to having your pull request reviewed, the reviewer(s) may ask you to complete additional design work, tests, or other changes before your pull request can be ultimately accepted.
    </details>

### Running tests

#### Test Environment Requirements

To run tests, you'll need to make sure that your development environment is setup correctly. You'll need:

* Ruby 3+ is installed on your system
* Install dependencies with `bundle install`

#### Executing Tests

* To run all tests: `bundle exec rake test`
* To run a specific test file: `bundle exec rake test TEST=test/controllers/callback_controller_test.rb`
* To run a single test: `bundle exec rake test TEST=test/controllers/callback_controller_test.rb:50` where `50` is the line number on or inside the test case.

### App Bridge client

This gem ships with a UMD version of the App Bridge client. It lives inside the assets folder: `app/assets/javascripts/shopify_app/`. To update the client, simply download the UMD build from [unpkg.com](https://unpkg.com/@shopify/app-bridge) and save it into the folder.
Please follow the convention of including the client version number in the filename. Finally, change the reference to the new App Bridge client inside `app/assets/javascripts/shopify_app/app_bridge_redirect.js`.
