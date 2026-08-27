# A skill that scaffolds v12 integrations — for our agents and for partners'

**Status:** planning. Developer experience, aimed outward. The premise is that a partner's agent should
be able to write a correct Smile ID v12 integration on the first attempt, and that the way to make that
true is to ship what we have learned rather than expect them to rediscover it.

The reference points are libraries that already do this well: Expo and RevenueCat ship agent-readable
guidance alongside the package, so any AI stack integrating them starts from the library's own knowledge
instead of from a model's recollection of an older major version. We are unusually well placed to copy
that, for two reasons in §2.

## 1. The problem this solves

An agent integrating v12 today reconstructs it from a training set that mostly contains **v11**. Every
v11-shaped answer is confidently wrong in a specific way — the builder DSL is new, the token session is
new, the job types moved, the config surface is typed where it used to be flag pairs. The failure mode is
not "the agent doesn't know"; it is "the agent knows the previous version".

Meanwhile every trap that costs a partner a day is already written down somewhere in this org — a device
ledger, a review thread, a plan doc, a memory. It is just not written down anywhere a partner's agent can
read.

## 2. Two facts that make this cheap

**2.1 The distribution channel already exists.** `AGENTS.md` records that *each Smile ID SDK repo pins
this repository as a git submodule*. So a skill authored here is already reachable from all four SDK repos
with no new sync mechanism, no publishing step, and no fifth place to keep current. One source, four
consumers — the same property that makes `sample-ui` worth having.

**2.2 The harvesting loop already exists, pointed inward.** `tools/verify/` keeps a findings ledger, and
the `harness-muse` skill exists specifically to *turn verification scar tissue into shareable ideas*. That
is precisely the input this skill needs; it is currently aimed at improving our own harness. Pointing the
same harvest at an outward-facing artefact is a redirection, not a new pipeline.

So the plan is mostly **assembly and discipline**, not invention.

## 3. What it must contain

Four parts, and the order matters — an agent reads the first thing that looks relevant and stops.

**3.1 A version assertion, first.** Before anything else: state the current major, state that v11 shapes
do not apply, and give the one-line check that tells an agent which version a project is actually on. A
skill that opens with capabilities gets skimmed; a skill that opens with "your training data is probably
wrong about this" gets read.

**3.2 Canonical flow recipes, per product, per platform.** Six products × four platforms is the matrix,
and the recipes should be extracted from the working sample rather than written fresh — the sample already
composes every journey, and a recipe that diverges from it is a recipe that is wrong. Each recipe carries
the *shape* (which screens compose, in what order) and the required inputs, because the commonest failure
is a builder that compiles and then rejects at flow start.

**3.3 The gotcha set — the actual value.** This is what a partner cannot derive from the API surface.
Seeded from what is already known, grouped by where it bites:

- **Journey composition** — a complete consent binding drops the consent screen at runtime, so a
  token-bound run starts at instructions; Enhanced KYC has no capture stage at all, consent and
  processing only; declaring a screen the token already satisfies ends the run before it starts.
- **What a token does and does not relax** — it relaxes user details and consent, never ID parameters;
  its PII is vault-tokenised, so prefilling a name or an ID number from a token is impossible, and only
  presence flags are readable.
- **`allowOfflineMode` is not "save locally"** — it skips token decoding and silently withdraws every
  relaxation above. This one has cost time already.
- **Camera ownership** — a host that owns a camera must release it before handing off, or the SDK
  receives a busy camera; and a default capture resolution that suits faces can be too low for dense
  QR.
- **Validation semantics** — which conditions are warnings and which block the build, and the fact that
  `validate()` is not a warning path.
- **Release builds** — minification and resource shrinking must be on, and are *off* by default in at
  least one platform's template, so a debug-only integration proves very little.
- **Per-platform install traps** — the mandatory worklets Babel plugin on React Native without which
  capture dies at runtime; peer dependencies silently dropped by a legacy-peer-deps install; iOS plugin
  resolution and framework embedding.
- **Metadata coherence** — device model reported in image metadata must match the job's, which
  production checks and sandbox does not.
- **The Huawei modules need a repository nothing tells you about.** Adding the Huawei pair to a
  Play-services build fails at resolution, and `developer.huawei.com` appears **nowhere** in the SDK
  README or the mobile documentation pages — so a partner following the docs literally cannot get there.
  This is the clearest example of why the gotcha set is worth having: the fix is one repository
  declaration, and the cost of not knowing it is a blocked integration.

**3.4 A verification recipe.** How a partner proves their integration works before shipping: the sandbox
test identities and what each deterministic outcome is for, that an arbitrary but well-formed ID number is
fine because matching is on name and email, and that a real successful submission needs a test identity
rather than plausible-looking data. This turns "it seems to work" into "it demonstrably reaches every
outcome".

## 4. The two hard problems, and what they need

**4.1 Rot. A stale skill is worse than no skill**, because it converts a model's uncertainty into
misplaced confidence. Prose cannot be trusted to stay true across four SDKs and a release cadence.

The mechanism that fixes this is already a technique in use in this org: **every snippet in the skill
compiles in CI.** A documentation-as-code harness extracts each code block, builds it against the
published SDK, and fails the lane when a snippet no longer compiles. That is what makes the difference
between a document and a contract — and it composes directly with the registry-consumption lane, since
both want "does this build against what partners can download?"

Snippets that cannot compile (a Gradle fragment, a plist entry) get symbol-existence checking instead:
assert the named types and fields still exist in the published API. Weaker, still mechanical.

**4.2 "Self-learning" has to mean a ritual, not an aspiration.** Nothing updates itself. What can be true
is that **the moment a lesson is learned is the moment it is written**, and that the write is cheap enough
to actually happen. Concretely: a device finding, a partner-integration defect, or a review thread that
turned out to be a real trap gets appended to the gotcha set in the same PR that fixes it — the same rule
this repo already applies to plan docs riding with their code. The muse loop then becomes the periodic
sweep that catches what the in-the-moment rule missed.

Two guards worth building in from the start. Every gotcha carries **the version it was observed on**, so a
fixed one can be retired rather than accumulating forever into noise — a gotcha list that only grows
eventually stops being read. And each entry states the **observable symptom**, not just the cause, because
a partner's agent matches on the error it is looking at.

## 5. What this is not

Not a replacement for the docs — `docs-v3` remains the reference, and the skill should link to it rather
than restate it, or the two will drift and the drift will favour whichever an agent read first. Not a
tutorial for humans. And not a place for anything internal: it ships to partners, so the never-commit list
and the internal-marker discipline apply in full, and this is the artefact where an unmarked internal
reference is most likely to be noticed by exactly the wrong audience.

## 6. Work items

| ID | Item | Notes |
|---|---|---|
| SKL-1 | Skill skeleton here, with the version assertion and the trigger description | Authored in this repo; the submodule pin distributes it. Model the frontmatter on the workspace's existing skills |
| SKL-2 | Extract the Android flow recipes from the working sample rather than authoring them | A recipe that diverges from the sample is wrong by construction |
| SKL-3 | Seed the gotcha set from §3.3, each entry with a symptom and an observed-on version | The part a partner cannot derive |
| SKL-4 | Snippet compile harness: extract, build against the published SDK, fail on drift | §4.1. The anti-rot mechanism |
| SKL-5 | Symbol-existence checks for the non-compilable snippets | Weaker but mechanical |
| SKL-6 | The append ritual, written into `AGENTS.md` so it is a rule and not a habit | §4.2 |
| SKL-7 | Retirement pass: drop gotchas fixed in a shipped version | Keeps the list readable |
| SKL-8 | Per-platform recipes for iOS, Flutter and Expo | Rides with each port |
| SKL-9 | Publish Tier 0 (docs page) and Tier 1 (`skill/` in the package) from one source | §7. Later phase; the format decision lands now so neither becomes a rewrite |

## 7. How partners get it — a channel already exists, and it is the best one

This was the open question. Checking rather than assuming changed the answer: **`docs.usesmileid.com`
already publishes a complete AI-readable channel.** `llms.txt` (≈21 KB) indexes every page as a `.md`
URL, and `llms-full.txt` serves **the entire documentation corpus as one file (≈960 KB)**. Both answer
200 today. Nothing had to be built for this; GitBook has been doing it all along.

That reorders the options, because reach-per-unit-of-work is now wildly uneven.

| Tier | Channel | Reach | Cost | Verdict |
|---|---|---|---|---|
| 0 | A docs page, picked up automatically by `llms.txt` / `llms-full.txt` | any agent with web access, no install, no partner action | **already running** | **do first** |
| 1 | `skill/` inside each published SDK package | agents in a project that has the SDK — works offline | SDK packaging agreement | **do second** |
| 2 | The public sample-apps repo plus a root `AGENTS.md` | agents working in a clone | free once public | automatic |
| 3 | A Claude Code plugin / skill marketplace entry | discoverable by name, Claude Code users only | small, ongoing | later |
| 4 | A hosted MCP server | highest capability — can answer queries and serve version-specific recipes | operationally expensive | on demand only |

**Recommendation: ship Tier 0 and Tier 1 as a pair, and treat 2 as a freebie.** Tier 0 gets the guidance
in front of every partner's agent immediately using infrastructure that is already live and already
maintained. Tier 1 covers the case Tier 0 cannot — an agent working offline, or one that never fetches a
URL, in a project that already has the SDK installed. Between them they cover essentially every partner.

Three things worth deciding deliberately rather than discovering:

- **`llms-full.txt` is already ~960 KB, and adding to it dilutes.** An agent ingesting the whole corpus
  may never surface the integration recipes specifically. So the skill needs to be **findable by name** in
  `llms.txt` — a clearly titled page at a stable path — rather than relying on the full-corpus dump. A
  short "for AI agents" entry point in the docs would do more for discovery than more prose would.
- **Tier 0 and Tier 1 must not drift.** One source, published two ways — the docs page generated from the
  same file the package ships, not maintained twice. The moment they are two documents they are two
  answers, and an agent will find the stale one.
- **Tier 4 is the tempting wrong first move.** An MCP server is the most capable option and the one most
  likely to be proposed; it is also the only one with an ongoing operational burden, and it reaches fewer
  partners than a URL does. It earns its place only once there is demand Tier 0 and Tier 1 cannot serve.

Publishing is a later phase either way — the immediate work is SKL-1 through SKL-4, authoring the skill
and making it self-verifying. But the channel decision shapes the format, so it belongs in the plan now:
**write it as a single Markdown file that is simultaneously a valid docs page and a valid skill**, and
both tiers become publishing steps rather than rewrites.
