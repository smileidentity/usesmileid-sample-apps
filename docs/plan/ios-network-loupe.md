# Loupe — the iOS shell's network inspector

## What it is

A pill sits over the app showing what its traffic is doing; tapping it opens a viewer with every
HTTP exchange this launch — the request, the response, the timing, a `curl` that reproduces it, and
an export of the whole session. Debug builds only.

It exists because the sample app's whole job is to prove the published SDK works, and when a flow
fails the first question is always what went over the wire.

## Where it came from, and what that obliges

Ported from [netfox](https://github.com/kasketis/netfox) (MIT, © 2015 Christos Kasketis). The
architecture is netfox's: a `URLProtocol` that replays each request through a private session so it
can record both halves, and a store the viewer observes.

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

**No shake, after review.** netfox opened on one because it had no visible chrome. Reading a shake
from SwiftUI costs a `UIWindow` category overriding its own class's method, which is undefined
behaviour and would have changed `UIWindow` in release builds too. The overlay is chrome, so the
gesture bought nothing and was removed.

**A streamed request body is never read.** Reading `httpBodyStream` consumes it, and the record is
taken before the request is forwarded — so capturing one would empty the body out of the very
request being observed. Streamed bodies are reported as streamed. An inspector that changes the
traffic is worse than one that misses part of it.

## Borrowed from DebugOverlay-Android

[DebugOverlay-Android](https://github.com/Manabu-GT/DebugOverlay-Android) (Apache-2.0) is a
different tool — a runtime diagnostics overlay — and none of its code is here. Three of its ideas
are:

**An always-visible overlay, not only a gesture.** Its headline is a draggable pill over the app
that opens a panel. A shake nobody is told about is a feature nobody uses, and a count on screen is
what makes a stall or a run of failures noticeable before anyone thinks to look. Loupe's pill shows
in-flight first, then failures, then the plain count, and drags anywhere on screen; it is clamped to
the container so it cannot be stranded off-screen.

**A report, not a dump.** Its bug report bundles diagnostics with the log so a repro arrives as one
artefact. Loupe's export leads with the app, bundle, system and the window it covers, then the
totals, then the traffic — one paste into an issue.

**Clearing scopes the next report.** Its toolbar wipes entries "so the next bug report covers only
the repro window". Loupe's clear restarts the window, and the report names when it opened, so a
reader knows what the transcript does and does not cover.

Not borrowed: CPU, heap, FPS and thermal readouts. Those belong to Instruments, and this repo's
rules are explicit that a sample which reimplements the platform stops being a sample.

## In-flight requests, which neither tool had

netfox and DebugOverlay both record an exchange when it completes, so a request that never comes
back is invisible in both — the case most worth seeing. A record is now reported when the request
is sent and replaced when it finishes, which is why the store upserts by id rather than appending.

## What was not ported

The macOS viewer, the demo app, netfox's own logo and font assets, and its shake trigger. The
session log file is replaced by the share export, which produces the same transcript without leaving
it on disk.
