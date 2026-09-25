# Security policy

## Reporting a vulnerability

**Do not open a public issue for a security problem.** Report it privately through GitHub instead:
open this repository's **Security** tab and choose **Report a vulnerability**. Only the maintainers
see the report, and the conversation stays private until a fix is released.

Include what you found, the steps to reproduce it, and the platform and SDK version you saw it on.

## What belongs here

This repository holds four sample apps that consume the Smile ID SDKs from their public registries.
Report here anything in the apps themselves or in this repository's CI.

A vulnerability in a Smile ID SDK can be reported here the same way. Say which SDK and version, and
the maintainers route it to that SDK's team.

## Credentials

The apps run against the Smile ID **sandbox** by default and ship no API key. Never paste a
production token, partner id or API key into an issue, a pull request or a log. If you have exposed
one, rotate it in the Smile ID Portal first, then tell us.
