# Loupe — the iOS shell's network inspector

## What it is

A shake opens a viewer over whatever is on screen showing every HTTP exchange the app has made this
launch: the request, the response, the timing, a `curl` that reproduces it, and an export of the
whole session. Debug builds only.

It exists because the sample app's whole job is to prove the published SDK works, and when a flow
fails the first question is always what went over the wire.

## Where it came from, and what that obliges

Ported from [netfox](https://github.com/kasketis/netfox) (MIT, © 2015 Christos Kasketis). The
architecture is netfox's: a `URLProtocol` that replays each request through a private session so it
can record both halves, a store the viewer observes, and a shake to open it.

The code is not netfox's. It was rewritten for this repo's floor — Swift 6 language mode on iOS 17 —
and the macOS half and demo app were dropped. Renaming it to Loupe is a product decision and changes
nothing about the licence: the MIT notice ships, verbatim and with its holder line, through
`scripts/license-texts/netfox.txt` and the `VENDORED` list in `generate_ios_licenses.py`, so it
appears on the app's licences screen alongside every other component. This repo goes public, and its
pre-flip checklist requires third-party licences confirmed redistributable.

## Decisions worth not re-arguing

**Vendored, not a dependency.** The repo's rule is registry-only SDK dependencies; a debug tool is
not an SDK, but adding a package for it would still put a third-party artifact in the graph the
release lane resolves. Vendoring keeps it out of release entirely, because the whole thing is behind
`#if DEBUG`.

**Debug only.** Recording replays every request through a second `URLSession`. That is a change to
how the app reaches the network, and the release lane exists to prove the published SDK works in the
configuration a partner ships — not in one where a debug tool sits in the request path.

**A lock, not an actor, for the configuration.** `URLProtocol.canInit(with:)` is a nonisolated static
the loading system calls on its own threads: it cannot read main-actor state and cannot await. netfox
read a mutable singleton from there, which Swift 6 rejects and which was a race before that. A lock
around an immutable `Sendable` snapshot is the smallest thing that is correct.

**Records are values, captured whole.** netfox wrote bodies to the caches directory and read them
back on demand, which bought a longer history at the cost of a record describing a file a later
request had overwritten — and left a partner's traffic on disk after the run. Bodies are held in
memory and the history is capped instead.

**Prefixes, not regular expressions, for the skip list.** netfox compiled user-supplied patterns with
`preconditionFailure` on a bad one, so a typo crashed the app being debugged.

**Registering is not enough on its own.** `URLProtocol.registerClass` covers `URLSession.shared` and
any session built from a configuration that has not replaced `protocolClasses`. A session the app
builds with its own list never consults the registry, so it passes through `Loupe.instrument(_:)`
first. netfox swizzled `URLSessionConfiguration` to avoid that call; a one-line opt-in is worth more
than a method swizzle in a sample app.

**The shake is read at the window.** Motion events travel the responder chain, and a SwiftUI view
cannot become first responder for them. A `UIWindow` override posts a notification, which keeps the
UIKit detail out of the shell.

## What was not ported

The macOS viewer, the demo app, and netfox's own logo and font assets. The session log file is
replaced by the share export, which produces the same transcript without leaving it on disk.
