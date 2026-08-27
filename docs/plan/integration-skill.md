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
| SKL-2b | Split the material into **several narrow skills** — builder, token session, document capture, v11 migration, sandbox verification, release config | §7.2. One monolith is the wrong unit; Expo's decomposition is the model |
| SKL-3 | Seed the gotcha set from §3.3, each entry with a symptom and an observed-on version | The part a partner cannot derive |
| SKL-4 | Snippet compile harness: extract, build against the published SDK, fail on drift | §4.1. The anti-rot mechanism |
| SKL-5 | Symbol-existence checks for the non-compilable snippets | Weaker but mechanical |
| SKL-6 | The append ritual, written into `AGENTS.md` so it is a rule and not a habit | §4.2 |
| SKL-7 | Retirement pass: drop gotchas fixed in a shipped version | Keeps the list readable |
| SKL-8 | Per-platform recipes for iOS, Flutter and Expo | Rides with each port |
| SKL-9 | Delivery: public skills repo → generated docs pages → hub page, from one source | §7.3. Later phase, deliberately. **Do not flip the internal `claude-skills` repo public** — its history was written for an internal audience |

## 7. How partners get it

Delivery is a later phase by decision — the immediate work is authoring (§6, SKL-1…SKL-4). But two
things belong in the plan now, because they change the *format* and one of them changes the repo layout.

### 7.1 The channel that already exists

`docs.usesmileid.com` already publishes a complete AI-readable surface: `llms.txt` (≈21 KB) indexes every
page as a `.md` URL, and **`llms-full.txt` serves the entire corpus as one ≈960 KB file**. Both answer 200
today, on infrastructure nobody has to build or maintain for this. Any agent with web access can ingest
the guidance with no install and no action from the partner. That is the highest reach per unit of work
available, and it costs a page.

One caveat that shapes authoring: `llms-full.txt` is already large, and adding to it dilutes. The skill
has to be **findable by name** at a stable path in `llms.txt`, not reliant on an agent reading a
960 KB dump.

### 7.2 A dedicated skills repo — the right source of truth, with one decision in the way

The model worth copying is Expo's, and it is more specific than "publish a skill":

- one repo, `github.com/expo/skills`, laid out as `plugins/expo/skills/<name>/SKILL.md`
- **one install command, agent-agnostic**: `bunx skills add expo/skills` — not Claude-specific, so a
  single repo serves Claude Code, Cursor and anything else that speaks the convention
- a branded landing page at `expo.dev/expo-skills` listing each skill with a one-line description and a
  link straight to its `SKILL.md`
- and the part most worth stealing: **many narrow skills, not one monolith** — `expo-upgrade`,
  `expo-data-fetching`, `expo-brownfield`, `eas-app-stores`, and a dozen more, each triggered by a
  specific task

**This changes §3's shape.** One "how to integrate v12" skill is the wrong unit. The Smile ID
decomposition falls out of the work naturally: the flow builder, the token session, document capture,
migrating from v11, verifying in sandbox, release configuration. An agent then loads only what the task
needs, and each skill gets a precise trigger instead of one broad one — which is also what makes the
version assertion in §3.1 land, because it can be repeated in the two or three skills where a v11 memory
actually causes damage.

**The decision in the way:** `smileidentity/claude-skills` **already exists** — private, described as
*"Shared Claude Code skills for Smile Identity engineers"*, actively updated. So the tempting move is to
flip it public and add partner skills to it. **I would not.** Making a repo public publishes its **entire
git history**, which is the same rule this repo already lives by in its own going-public checklist — and
`claude-skills` has been accumulating internal engineering skills for months, written for an internal
audience, with no expectation that any of it would ever be read by a partner. Auditing that history is a
strictly worse job than starting clean.

So: **a second, public repo** — born public, partner-facing from its first commit, with the internal
`claude-skills` left alone to do its own job. It also gets an independent release cadence from the four
SDKs, which is what makes the append ritual in §4.2 realistic; a gotcha can land the day it is learned
rather than waiting for a version bump.

### 7.3 What that leaves, ranked

| | Channel | Reach | Cost |
|---|---|---|---|
| **1** | Public skills repo, Expo-shaped, one install command | any agent, any stack, versioned, independently releasable | one new repo |
| **2** | Docs pages generated from that repo, picked up by `llms.txt` | any agent with web access, zero install | a publish step |
| **3** | A branded hub page, the `expo.dev/expo-skills` equivalent | discovery and credibility; also feeds channel 2 | a docs page |
| **4** | `skill/` inside each published SDK package | already present in a partner's project, works offline | four SDK repos must agree a packaging change, and it adds bytes to every artefact |
| **5** | A hosted MCP server | highest capability — queries, version-specific answers | ongoing operational burden |

**Recommendation: 1, 2 and 3 as one piece of work, from one source.** The repo is the source of truth, the
docs pages are generated from it, the hub page is the front door. Channel 4 stays a real option but is no
longer the lead: it was in the lead only because a repo was not on the table, and it is the one that
requires agreement from four other repos. Channel 5 remains the tempting wrong first move — most capable,
only one with ongoing ops cost, and it reaches fewer partners than a URL.

**What this settles now, before any of it is built:** author each skill as a standalone `SKILL.md` under a
`plugins/`-shaped path, narrow in scope, with a precise trigger description — so publishing to a repo, to
the docs, and into a hub page are all publishing steps rather than rewrites.
