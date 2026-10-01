# "Capture as" follows the document

**Status:** planning. Phases 1 and 2 can start now. Phase 3 is deferred (§8).

## 1. The problem

On the document products, the form has a DOCUMENT trigger and a CAPTURE AS trigger under it. Today the
two are independent, and "Capture as" defaults to **Generic document** whatever the document is.

Pick **Passport** as the document and leave "Capture as" alone, and the SDK receives
`GenericDocument(displayName = "Document", hasBackSide = true, orientation = Landscape)`. The person
holding a passport then sees:

- a landscape card guide, not the passport page guide;
- a request for a back side, because the front-only rule is `captureBothSides && captureAs != Passport`
  and reads the "Capture as" field, not the document;
- the label "Document", not "Passport".

Pick a **one-sided card** and the same thing happens in a smaller way: the SDK asks for a back side the
catalogue says the document does not have. That is not a passport-only defect. It is a third of the
catalogue (§2).

This is the behaviour the spec asks for: `spec/catalogue-rules.json` → `captureAs` has a case named
"Nothing is inferred from the API: a passport row under Generic document stays generic". It is still
the wrong default for most people using the app. The app is public on both stores, and someone who
picks a document expects to see how the SDK captures that document. When it does not, it reads as an SDK
defect.

Picking a different document also leaves an earlier choice in place: all four apps' document setters
keep `captureAs`, so a Passport preset chosen for a passport survives a switch to an identity card.

A third gap sits under both: the apps asked for `supported_documents?continent=AFRICA`, so the country
picker offered 56 countries where the SDK and the previous major version support every one the API
lists. That filter is gone (D7); the rest of this plan is written against the whole catalogue.

## 2. What the catalogue actually contains

Fetched from `GET /v3/services/supported_documents?locale=en` (no `continent`) and
`GET /v3/services/supported_id_types` on 2026-09-29. Production and sandbox returned byte-identical
bodies. `locale` has no effect on `supported_documents`: `en`, `fr`, `sw`, `pt`, an unknown value and no
value at all return the same body, so the names are English whatever is asked for.

**The two catalogues use different codes.**

| Endpoint | Read by | ID card | Passport |
|---|---|---|---|
| `supported_documents` | the document products, where "Capture as" lives | `IDENTITY_CARD` in 195 of 226 countries; `NATIONAL_ID` never appears | `PASSPORT` in 207 of 226, always `format 3`, `has_back false`; the 19 without one are territories |
| `supported_id_types` | the KYC products, which have no "Capture as" | `NATIONAL_ID` (ET, KE, NG, ZA), `NATIONAL_ID_NO_PHOTO` and others | `PASSPORT` (GH, KE, NG) |

So a varying national-ID code cannot reach a document capture. Only `supported_documents` matters here.

**Facts the match table (D2) relies on:**

- `green_book` is the **only** `sub_types` entry in the whole catalogue: South Africa, under
  `IDENTITY_CARD`, `display_standalone true`, `format 7`, `has_back false`.
- `PASSPORT` is the same code in every country that has one.
- `format` is not a safe key. `SEAMANS_ID` is also `format 3` in 50 countries and `has_back` varies;
  `IDENTITY_CARD` is `format 5` in Ghana; Zambia's `REGISTRATION_CERTIFICATE` is `format 6`. A
  format-keyed match would give seaman's books the Passport preset.
- `has_back` **is** a safe key, and Match needs it. Of the 1,350 listed rows, 394 have `has_back false`
  and are not passports: `TRAVEL_DOC` (145), `HEALTH_CARD` (34), `SEAMANS_ID` (34), `DRIVERS_LICENSE`
  (21), `RESIDENT_ID` (20) and others. The SDK's `GenericDocument` default of `hasBackSide = true` is
  wrong for every one of them, and the fixture already says so: its `KE ALIEN_CARD` case is described as
  "a one-sided card, which a GenericDocument must not ask a back side of". Nothing tests that today.
- Every country has an "Others" row whose `code` is empty. The `documents` rule already leaves it out,
  so Match never sees it.
- `RESIDENT_ID` is a residency card or permit (`format 1`). It is an ordinary card and stays Generic.

Every other document, in every country, is a card or booklet for which a `GenericDocument` is right once
its `hasBackSide` follows the row. Two documents need a preset of their own.

## 3. The two special cases

| | Kind | Catalogue identity | SDK rules on the current SDK `main` |
|---|---|---|---|
| **Passport** | a document | `code == "PASSPORT"` | `DocumentType.Passport`: landscape, `hasBackSide` true so a host can opt into the back. The SDK's own default for `captureBothSides` is `false` for this type; the released SDKs the sample pins do not have that default yet, so the sample sets the flag itself (D6) |
| **Green Book** | a document | `sub_types[].id == "green_book"`, submitting the parent `IDENTITY_CARD` | `DocumentType.SouthAfricaGreenBook`: portrait, no back side. **Refused at build on Enhanced Document Verification** ("South Africa Green Book is not supported for Enhanced Document Verification"), with the SDK's suggested fix being to use Document Verification for that document |

## 4. Decisions

**D1. The default is "Match document". The three presets stay as manual overrides.**
The sample used to derive the type from the ID type, which made the presets impossible to test on
their own. That is why they became independent. Keeping every preset selectable preserves that: a
scenario can still pair any document with any shape, including pairs the SDK refuses. What changes is
the default an untouched form produces.

**D2. The match table keys on code and subtype; the Generic fallback takes the row's `has_back`;
`format` is never read.**

| Document row | Resolves to |
|---|---|
| `subType == "green_book"` (any parent code) | Green Book preset |
| `code == "PASSPORT"` | Passport preset |
| anything else | `GenericDocument` with `hasBackSide = row.has_back` and the SDK's defaults for the rest |

The Green Book keys on the subtype alone so it keeps working if the parent code is renamed. An unknown
code falls back to Generic, which always captures successfully. `has_back` is the one field read from
the API: without it Match asks for the back of 394 one-sided documents, which is the §1 complaint in
another form. `format` stays unread because its values are undocumented and collide (§2).

The generic-document sheet is an override, not part of Match. Changing anything in it sets the override
to Generic document with exactly what the sheet holds, as today.

**D3. The trigger always shows what the SDK will get.**
Today the trigger shows only the choice ("Generic document"). It shows the result instead, and says
whether that result was matched or chosen:

| State | Trigger text |
|---|---|
| Match, passport | Passport preset · matches document |
| Match, Green Book on Document Verification | Green Book preset · matches document |
| Match, a two-sided card | Generic document · landscape · front and back |
| Match, a one-sided card | Generic document · landscape · front only |
| Override | Passport preset · chosen |
| Generic, changed in the sheet | Booklet · portrait · front and back · chosen |

"Front and back" is what the SDK will do: the resolved type's `hasBackSide` ANDed with the Settings
switch, so it reads "front only" when either is off. A Passport row reads front only whatever the
switch says (D6). The exact strings go in `spec/` so that all four apps render the same text.

**D4. Choosing a new document or country resets an override back to Match.**
An override describes one pairing. Carrying it across a document change is how an identity card ends up
with the Passport preset without anyone choosing that. All four country setters already clear the ID
type and document; they now clear the override too.

**D5. Match never offers a pair the SDK refuses, and a refused row is not listed.**
On Enhanced Document Verification the document picker leaves the Green Book row out, because the SDK
refuses that document on that product and its own message says to use Document Verification for it.
Resolving the row to Generic instead would capture a portrait, one-sided booklet as a landscape,
two-sided card and submit it to a product the SDK says cannot take it. Nothing is lost for testing: the
Green Book preset is still selectable on any row ("Green Book preset, whatever the document"), which is
how the build refusal is exercised.

**D6. The front-only rule reads the resolved type, not the field.**
`captureBothSides = settings.captureBothSides && resolved != Passport`. With D1 and D2 this makes a
passport front-only whether it was matched or chosen. A Generic override on a passport row still
captures two sides, because that is what Generic declares. The Settings switch keeps its meaning: the
SDK ANDs it with the type's `hasBackSide`, which is how a one-sided Generic ends up front only. The
SDK's `main` already defaults `captureBothSides` to `false` for a Passport; when a release with that
default is pinned on all four apps, the sample should leave the flag unset while the switch is on, so it
demonstrates the SDK's behaviour instead of re-deriving it.

Done with 12.2.0, which carries that default on all four SDKs, and taken one step further: the back-side
switch is gone. Capture as already matches the document and `has_back` already describes it, so the
sample never sets `captureBothSides` and the SDK decides from the type.

**D7. The apps read the whole catalogue** (already landed, recorded here for the reason).
`supported_documents` is fetched without `continent`, as `supported_id_types` always was and as the
previous major version's samples did: the SDK supports every country the API lists, and a partner
outside Africa reads this app too. One list serves every product, so nothing needs a second fetch or a
second store. The body is about 200 KB instead of 45 KB and is decoded off the main thread on every
platform already. The pickers list 226 countries; search is how a long list is used.

**D8. A scheduled check watches the live catalogue.**
The match table is only as good as the catalogue it was written against. A weekly workflow
(`.github/workflows/catalogue-watch.yml` with `scripts/catalogue_watch.py`, schedule and manual
dispatch, no secrets) fetches the unfiltered `supported_documents` from sandbox, which is byte-identical
to production, and fails when any of these is true:

- a document `code` appears that the script's known-code list does not have;
- a `sub_types` id appears that the `captureAs` cases in `spec/catalogue-rules.json` do not name, which
  is where the script reads its subtype table from, so the two cannot drift;
- the `ZA` `IDENTITY_CARD` row no longer carries `green_book`;
- a `PASSPORT` row has `has_back true` or `sub_types`, or the number of `PASSPORT` rows drops below the
  recorded count. A renamed passport code would otherwise look like one more territory without one.

Locale and row order are not compared, because the endpoint ignores the one and the check compares sets.
A failure means someone has to decide on a preset. Until then the app keeps working, because unknown rows
fall back to Generic.

## 5. Model change

Replace `captureAs: CaptureAs = GenericDocument` in the ID details with an optional override:

- `captureAsOverride: CaptureAs? = null`. Null means Match.
- One pure function, `resolvedCaptureAs(document, override) -> Resolved`, is the only place D2 lives.
  It returns the SDK type to build, including the Generic fallback's `hasBackSide`. The flow builder,
  the trigger text and the front-only rule all call it.
- The sheet lists four rows: **Match document** first (its row names what it resolves to, for example
  "Match document (Passport preset)"), then the three presets. The new option id is `matchDocument`, so
  its test ID is `sample_capture_as_option_matchDocument`.
- The document picker takes the product, so D5 can leave a row out.
- Only Android saves the form across process death (`UseSmileIDSampleForms.Saver`); the other three
  hold it in memory and start the form afresh. The Android saver writes the override's name or an empty
  field, and an unknown value restores as Match. This is not durable storage, so nothing migrates.

## 6. Where it lands, per platform

| Concern | Android | iOS | Flutter | Expo |
|---|---|---|---|---|
| Model | `sample-ui/.../state/UseSmileIDSampleIdDetails.kt` | `SampleUI/.../State/UseSmileIDSampleIdDetails.swift` | `sample_ui/lib/src/state/use_smileid_sample_id_details.dart` | `sample-ui/src/state/use-smile-id-sample-id-details.ts`, `src/model/use-smile-id-sample-capture-as.ts` |
| Form setters and reset (D4) | `sample-ui/.../state/UseSmileIDSampleForms.kt`, which also holds the saver | `App/Sources/State/UseSmileIDSampleAppState.swift` (`selectCountry`) and `App/Sources/UseSmileIDSampleShell.swift` (the document and capture-as sheet writes) | `app/lib/src/state/use_smileid_sample_forms.dart` | `sample-ui/src/state/use-smile-id-sample-forms-store.ts` |
| Sheet | `sample-ui/.../screens/CaptureAsSheet.kt` | `SampleUI/.../Screens/CaptureAsSheet.swift` | `sample_ui/lib/src/screens/use_smileid_sample_document_sheets.dart` | `sample-ui/src/screens/capture-as-sheet.tsx`, `app/app/flow/[productId]/id-details/capture-as.tsx` |
| Trigger (D3) | `sample-ui/.../screens/KycIdFormScreen.kt` | `SampleUI/.../Screens/KycIdFormScreen.swift` | `sample_ui/lib/src/screens/use_smileid_sample_kyc_form_screen.dart` | `sample-ui/src/screens/kyc-id-form-screen.tsx` |
| Document list (D5) | `sample-ui/.../state/UseSmileIDSampleCatalogue.kt`, `screens/DocumentPickerSheet.kt` | `SampleUI/.../State/UseSmileIDSampleCatalogue.swift`, `Screens/DocumentPickerSheet.swift` | `sample_ui/lib/src/state/use_smileid_sample_catalogue.dart`, `screens/use_smileid_sample_picker_sheets.dart` | `sample-ui/src/state/use-smile-id-sample-catalogue.ts`, `screens/document-picker-sheet.tsx` |
| Mapping + front-only (D2, D6) | `app/.../flow/FlowBuilderConfig.kt` (`documentTypeFor`, line ~250; the front-only rule at ~243) | `App/Sources/Flow/FlowBuilderConfig.swift` (~285 to ~300) | `app/lib/src/flow/use_smileid_sample_flow_builder_config.dart` (~190, ~292) | `app/src/flow/use-smile-id-sample-flow-builder-config.tsx` (~270, ~303) |

## 7. Tests and docs

Changing `spec/` where four apps already implement it needs an explicit go-ahead first; this plan is
that request, and the PR says so.

**Spec.**
- Rewrite the `captureAs` rule in `spec/catalogue-rules.json` and its rule text, which today says
  nothing is read from `has_back`. Replace the two "Nothing is inferred" cases with Match cases: a
  two-sided identity card resolves to Generic with a back; a one-sided card (`KE ALIEN_CARD`) to Generic
  without one; a passport to the Passport preset; the Green Book to the Green Book preset on Document
  Verification; a `SEAMANS_ID` row to Generic; an unknown subtype to Generic.
- Keep the override cases ("Passport preset, whatever the document" and the rest) unchanged; the old
  "passport row under Generic document" case becomes the Generic-override case.
- Add a case each for D4 (document change and country change reset the override) and D6 (passport
  front-only when matched and when chosen; two sides under a Generic override; front only for a
  one-sided Generic).
- Add a case for the trigger text of every state in D3.
- Add to the `documents` rule: the Green Book row is not listed on Enhanced Document Verification (D5).
- Add `matchDocument` to `spec/test-ids.json` and `spec/screens.json` (`captureAsSheet`), and rewrite
  both entries' prose, which still says Generic document is the default and that the sheet has three
  rows.
- `spec/catalogue-fixture.json` already has `KE ALIEN_CARD`, `ZA IDENTITY_CARD green_book` and
  `KE PASSPORT`. Add a `SEAMANS_ID` row with `format 3` as the format-key trap, then run
  `scripts/sync_catalogue_fixture.py` for the Flutter and Expo copies.

**Unit tests.** Every platform's catalogue-rules spec test and document-capture mapping test run the new
cases:
- Android: `DocumentCaptureMappingTest`, `SdkFlowPreflightTest`
- iOS: `UseSmileIDSampleDocumentCaptureMappingTest`
- Flutter: `use_smileid_sample_document_capture_mapping_test.dart` and the catalogue-rules spec test
- Expo: `use-smile-id-sample-document-capture-mapping.test.ts`

A new test proves that Match never produces a flow the SDK refuses, for every row in the fixture on both
document products. The builder's `validate()` cannot prove it on any platform: it checks the builder's
own state and never runs the job-type rules, which is why `SdkFlowPreflightTest` as written passes
either way. The rules run in `build()`, which is public on Flutter and React Native and internal on
Android and iOS. On those two the public path is the dispatching validator,
`FlowValidator.validate(configuration, …)` on Android and
`FlowValidator.validate(configuration:mlAnalyzerRegistry:networkClient:)` on iOS, given a
`FlowConfiguration` built from the sample's own steps, which the iOS preflight already constructs. The
same call makes the Android and iOS preflights see job-type refusals, which they cannot today.

**Goldens.** Re-record the form (trigger in Match, override and Generic-sheet states, one-sided and
two-sided rows), the "Capture as" sheet, and the document picker on Enhanced Document Verification,
light and dark. Take the Flutter and Expo baselines from CI artifacts, not from a local run.

**Device flows.** All four assert on the default today and all four change:
- `android/maestro/document-options.yaml`, `flutter/maestro/document-options.yaml`,
  `expo/maestro/document-options.yaml` and `UseSmileIDSampleDocumentOptionsUITests.swift` assert that
  `matchDocument` is checked by default.
- Add a step that picks the passport row and asserts the trigger text says it matches.
- The Green Book step picks the preset explicitly, as it does now.
- `android/maestro/subflows/document-to-capture.yaml` needs no change if it keeps choosing a preset.

**Real device, once.** On Android and iOS, pick Passport with "Capture as" untouched, and confirm the
SDK shows the passport guide and never asks for a back side. Then pick a one-sided card and confirm the
same for it.

**Docs.**
- Rewrite the Capture as table in `docs/architecture.md`, add the D2 table and the §2 catalogue facts
  in short form, and update its §7 for the unfiltered fetch.
- Update `docs/testing.md` §4 for the new default.
- Delete this plan in the pull request that finishes phase 2. Anything still open in §9 moves to
  `docs/plan/backlog.md` in that same PR.

## 8. Phases

**Phase 1: Match document** (D1–D6), one pull request covering all four apps.
This follows the repo rule of mirrored structure, and the spec cases keep the four apps aligned.

**Phase 2: catalogue watch** (D8). A small separate pull request: the workflow plus a script the four
apps do not depend on.

**Phase 3: Residency Document Verification.** A job type on the SDKs' `main` that no release carries
yet. It becomes its own product entry, with the passport pinned and the visa step the SDK adds, once a
release ships it on all four registries and its partner documentation is published. Its design is kept
outside this repository until then, and `main` here keeps building against released SDKs.

## 9. Open questions

1. **Seaman's books.** `SEAMANS_ID` is a booklet (`format 3`). The recommendation is Generic, because the
   Passport preset's instructions and frame name a passport. Revisit if the SDK gains a booklet preset.
2. **An SDK helper.** A public `DocumentType` suggestion for a catalogue row would let partners use the
   same table instead of copying it. It is new public API on four SDKs, so it is out of scope here. It
   is worth raising if partners copy this table.

## 10. Done when

- An untouched form sends each document's own preset, a passport is captured front only, and a
  one-sided card is not asked for a back.
- The trigger names the type the SDK will get, and whether it was matched or chosen.
- Changing the document or country resets an override.
- The Green Book row is absent on Enhanced Document Verification, and no fixture row under Match builds
  a flow the SDK refuses, proven through the job-type rules on all four platforms.
- The country pickers list every country the API does.
- The weekly catalogue check is green.
