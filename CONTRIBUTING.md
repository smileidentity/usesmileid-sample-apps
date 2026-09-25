# Contributing

These apps are the reference integration for the Smile ID v12 SDKs, so a change here is judged by one
question: does it still show a partner exactly how a real integration behaves? `AGENTS.md` is the full
contributor guide, and it applies to people as much as to coding agents. Read it before your first
change.

## Before you open a pull request

- **Security problems go through [SECURITY.md](SECURITY.md)**, never an issue or a pull request.
- **SDK behaviour is not fixed here.** If something only works with a path dependency, an override or a
  patched build file, that is an SDK defect. Open an issue describing it, and leave the workaround out.
  The apps consume every SDK from its public registry, deliberately and permanently.
- **Change all four apps, or say why not.** A screen, scenario or behaviour added to one platform is
  added to the other three, and to `spec/` if it is part of the shared contract. If a change is
  genuinely platform-specific, the pull request says so.
- **Never commit a credential, a token, a partner id or captured images.** The apps run against the
  sandbox, and CI gets its credentials as repository secrets.

## Checks

Each platform has one script that is its definition of done, and CI runs the same script:

```bash
android/verify.sh
ios/verify.sh
flutter/verify.sh
expo/verify.sh
```

Run the one for every platform you touched. If you cannot run one, for example `ios/verify.sh` off a
Mac, say so in the pull request. A UI change also updates its golden images in light and dark. Flutter
and Expo baselines are recorded on the CI runner, not on a laptop (see `AGENTS.md` § Commands).

## Commits and pull requests

- Commits are a single conventional-commit subject line, such as `fix: keep the scan sheet above the
  nav bar`, with no body.
- A pull request title leads with an emoji and says what changed and why it matters, such as
  `🐛 flutter: keep the scan sheet above the nav bar`.
- The description says why the change was worth making, not only what it does, and lists what you ran.

## Questions

Integration questions are best answered by the [Smile ID docs](https://docs.smileidentity.com). For
anything this repository gets wrong or leaves unclear, open an issue.
