# Plan: document features

Status: approved 2026-09-28. Every sign-off item (S1–S9) takes the recommended option. No app code has changed yet.

This plan covers one pull request across all four apps. It does three things:

1. It lets you set the SDK's document-capture options (`DocumentCaptureConfig`) from the app.
2. It loads the supported documents and ID types for each country from the Smile ID API. Today
   each app has its own hard-coded list.
3. It makes the ID-number field show a hint for the chosen ID type, and check the number
   against that type's format.

The pull request that finishes the work also deletes this file. Anything worth keeping moves
into `docs/architecture.md` and `docs/testing.md`.

## Sign-off needed before any code

`AGENTS.md` says changes to parts of `spec/` that are already built need approval first. Each
item below changes something the four apps already implement, or makes a product decision this
plan should not make alone. The recommended option is listed first.

| # | Change | Recommendation | Alternative |
|---|---|---|---|
| S1 | `sample_idtype_option_*` suffix | Keep the rule "suffixed with the type id". The id is the API's `type` or `code` value exactly (`NATIONAL_ID`), which all four apps already emit. Only one iOS UI test uses a stale form (see iOS below) | None needed. This only makes the wording exact |
| S2 | ID types whose `type` repeats | A repeated `type` gets `_2`, `_3` added to its id, in API order. Today no repeat survives D5 (Ghana's three `PHONE_NUMBER` rows and Zambia's `BANK_ACCOUNT` rows all need fields the form lacks), so this is a guard, covered by a case in `spec/catalogue-rules.json` | Merge repeats into one row that accepts any of the regexes (rejected: the rows can need different field values) |
| S3 | The API's `Others` document, whose code is `""` | Leave it out of the document list | Give it a made-up id (rejected: the server has no code to receive) |
| S4 | Which fields the ID form shows, per product | Show the ID-number field only for Biometric KYC and Enhanced KYC. Document Verification and Enhanced Document Verification never send a number, but today they cannot continue without one | Keep three fields for every product, as `screens.json` says today |
| S5 | Sub-types, of which the Green Book is the only one today | The API lists the Green Book as a `sub_types` entry under South Africa's `IDENTITY_CARD` (`id: green_book`, `has_back: false`, `display_standalone: true`). A sub-type with `display_standalone: true` becomes its own row, "Green Book", right after its parent. It submits the parent's `IDENTITY_CARD`, because the server reads only `code`. Its option id is `IDENTITY_CARD_green_book` | Show sub-types nested under the parent row (rejected: one level of options is all the sheet has, and the flag asks for a standalone row) |
| S6 | Enhanced Document Verification has no v3 list of supported documents | Show all the country's `supported_documents` entries. If the server rejects one, the result card shows the rejection | Filter by `GET /v1/services` → `hosted_web.enhanced_document_verification`, as v11 did (rejected by default: it means this v3 sample calls a v1 endpoint) |
| S7 | New ids, states and one launch argument (listed in [Spec changes](#spec-changes)) | Add them. The design set has no frames for any of this, so this plan is the design (D9 for loading). Each new state is marked `"design": "in-repo"` in `screens.json` and described in `docs/architecture.md`, as `EmptyState` is | — |
| S8 | Device flows need fixed lists without the network (D3) | A small fixture in `spec/catalogue-fixture.json`, reached only through the `catalogue=fixture` launch argument, as `seedJobs` is. It is a test input that exercises the UI's cases (a two-sided card, a passport, a standalone sub-type, a type with a regex). It does not mirror the API, so it never needs updating when documents change | Let device flows hit the live API (rejected: a flow would go red because of the network or an API release, not the app) |
| S9 | ID types that need a date of birth | Leave them out (D5). The form collects no date of birth, and the SDK's KYC parameters have no field for one. This removes NG `NATIONAL_ID`, `PASSPORT` and `DRIVERS_LICENSE`, and KE `DRIVERS_LICENSE` and `KRA_PIN`. With D5's other exclusions, 30 of the 64 ID types remain | List them anyway and let the server decide (rejected by default: a demo of Nigeria's most common ID types would fail at submission). Step 0 checks whether the server really rejects a missing date of birth |

## What the SDK does today (checked at 12.1.1 on all four platforms)

- **The back side is already gated.** On all four platforms the SDK captures a back side only
  when the document type has one and `captureBothSides` is true:
  - Android: `FlowNavigationManager.documentCapturesBack`
  - iOS: `FlowNavigationManager.swift`
  - Flutter: `flow_navigation_manager.dart`
  - React Native: `flow_navigation_manager.ts`, and `orchestrated_capture_screen.tsx`

  So `SouthAfricaGreenBook` with `captureBothSides = true` already captures the front only.
  The backlog item's premise ("the Green Book is asked for two") is not what happens. The real
  defect is on the sample's side:
  - The app cannot choose the Green Book at all.
  - Every non-passport ID type becomes `GenericDocument(displayName = label)`, whose
    `hasBackSide` defaults to `true`.
  - So Kenya's Alien ID, which the API marks one-sided, is asked for a back side.
- **The SDK and the API disagree about passports.** The SDK's `Passport` preset has
  `hasBackSide = true`, and its own doc comment calls the values provisional. The API returns
  `has_back: false` for `PASSPORT` in NG, GH, KE and ZA. Setting `captureBothSides` from the
  API's value (D6) makes this disagreement harmless in the sample. It is still an SDK finding.
- **Metadata reports the setting, not what happened.** The metadata sends
  `capture_both_sides` as configured, not as applied. A Green Book run with
  `captureBothSides = true` reports `true` but captures one side. Setting the value from
  `has_back` fixes this for the sample. It is still an SDK finding.
- **Capture mode on the wire.** `captureMode` is sent as `auto_capture_enabled`:

  | Mode | Wire value |
  |---|---|
  | `AutoCapture` | `auto_capture_only` |
  | `ManualCapture` | `manual` |
  | `AutoCaptureWithManualFallback` (the default, 10 seconds) | `autocapture_default` |

  The same metadata object also carries `allow_gallery_upload` and `allow_skip_back`.
- **Gallery upload needs no runtime permission prompt.**
  - Android uses `PickVisualMedia`.
  - iOS uses `PHPickerViewController`, which runs out of process.
  - Flutter uses `image_picker`.
  - React Native uses `expo-image-picker`, which the Expo app already lists as a required SDK
    dependency.

  All three iOS targets (iOS, Flutter, Expo) already declare `NSPhotoLibraryUsageDescription`.
  So the "permission consequence" is a declaration that is already in place, not a prompt a
  flow can trigger. Step 2 confirms on a device which picker actually appears.
- **The SDK wraps neither endpoint.** None of the four SDKs calls `supported_documents` or
  `supported_id_types`.
- **Every SDK has a public network-interceptor hook.** Its name differs per platform:
  - Android: the `interceptors { }` block inside the flow builder's `network { }` configuration
  - iOS: the `Interceptor` protocol
  - Flutter: `NetworkConfiguration` and `InterceptorConfigBuilder`, exported
  - React Native: `NetworkConfig.interceptors`

  D8 uses this for the debug-only wire check.
- **The SDK publishes no ids for the manual shutter or the gallery button.** It has only the
  accessibility labels `si_cd_document_capture_shutter` and `si_cd_document_gallery`. Until the
  SDK publishes ids, device flows match those labels. This is an SDK finding.

## What the API returns (run against sandbox, 2026-09-28)

I called both endpoints without authentication, on `testapi.smileidentity.com`:

- `supported_documents` for NG, GH, KE and ZA
- the same for KE with `fr-FR`, `ar-EG`, no locale, and an unsupported locale
- `continent=AFRICA`
- country and continent together
- a lowercase country code
- an unknown country
- `supported_id_types` for the same four countries, for no country, and for an unknown country
- Kenya again on `api.smileidentity.com`

The public spec is `smileidentity/api-reference` → `specs/v3/v3-services.yaml`.

**`GET /v3/services/supported_documents?country_code=KE&locale=en-GB`**

```json
{"valid_documents":[{"country":{"code":"KE","continent":"AFRICA","name":"Kenya"},
  "id_types":[
    {"code":"ALIEN_CARD","example":["Alien Identity Card"],"format":1,"has_back":false,"name":"Alien ID"},
    {"code":"PASSPORT","example":["Passports"],"format":3,"has_back":false,"name":"Passport"},
    {"code":"","example":["My document is not listed"],"format":1,"has_back":true,"name":"Others"}]}]}
```

**`GET /v3/services/supported_id_types?country=KE`**

```json
{"id_types":[
  {"country":"KE","label":"National ID","regex":"^[0-9]{1,9}$",
   "required_fields":["country","id_number","id_type","partner_id","partner_params","timestamp"],
   "type":"NATIONAL_ID"}]}
```

What the responses show:

- **ID types have no example or format.** The only keys are `country`, `label`, `regex`,
  `required_fields` and `type`. So the hint has to come from `regex` (D7).
- **The documents' `example` field is a description, not a sample number.** It holds text such
  as "Consular IDs" and "National IDs". The spec's own example shows sample numbers
  (`AAA00000AA00`). This is an API reference finding.
- **`format` is a capture-shape hint that the public spec does not document.** Across Africa it
  takes five values:

  | `format` | Rows | What it is |
  |---|---|---|
  | 1 | 290 | Standard ID-1 card |
  | 3 | 59 | Passport or seaman's booklet |
  | 5 | 1 | Ghana `IDENTITY_CARD` |
  | 6 | 1 | Zambia `REGISTRATION_CERTIFICATE` |
  | 7 | 1 | The Green Book sub-type |

  The service's own tests confirm these meanings. D6 uses 3 and 7, and treats every other value
  as a generic card.
- **Documents can have `sub_types`.** Today there is one: the Green Book under South Africa's
  `IDENTITY_CARD`. It has `id`, `name`, `has_back`, `format`, `example` and
  `display_standalone`. Sub-types never reach the server, which reads only the parent's `code`
  (S5).
- **The lists are the same for every partner and every environment.** Both endpoints are built
  from static data that ships with each release of the service. They take no credential and no
  partner id, and read no partner configuration, which is why production and sandbox matched
  byte for byte.
  - The data changes when the API is released, and the apps pick the change up on their next
    fetch without an app update (D3).
  - Which ID types a partner's *account* is enabled for is a separate, signed, per-partner
    setting. v11 read it from `/v1/products_config`, and v3 has no unauthenticated equivalent.
    So a type in these lists can still be refused at submission for a partner who is not
    enabled for it, and the result card shows that refusal.
- **Locale translates names but not codes.** With `fr-FR` or `ar-EG`, the document names
  *and* the country name are translated ("كينيا"), and the codes stay the same. An unsupported
  locale (`sw-KE`) quietly returns `en-GB`. No locale also returns `en-GB`.
- **Filters and errors.**
  - Country and continent together returns 200, and the country filter wins, even though the
    spec says to pass only one.
  - A lowercase `ke` returns 400 with `{"code":"2413","error":"Country Code must be … uppercase letters."}`.
  - An unknown country returns 200 with an empty list, on both endpoints.
- **The same `type` or `label` can repeat within a country.**
  - Ghana has `PHONE_NUMBER` three times, one per operator's regex.
  - Zambia has `BANK_ACCOUNT` more than once, one per bank.
  - Kenya has the label "KRA PIN" twice (`KRA_PIN` and `TAX_INFORMATION`).
  - Nigeria labels both `NATIONAL_ID` and `NIN` "National ID".

  So rows are keyed by position in the list, and ids follow S2.
- **Some ID types need fields this form cannot collect.** `required_fields` sometimes
  includes `bank_code`, `session_id`, `operator`, `citizenship`, `dob`, `first_name` or
  `last_name`. The consent form already collects the names. The rest cannot be supplied (D5).
- **The two endpoints cover different countries.**
  - `supported_id_types` covers 10: CI, ET, GH, KE, NG, TZ, UG, ZA, ZM and ZW.
  - `supported_documents` for Africa covers 56.
  - The app offers Rwanda today, which has no KYC ID types.
  - Document Verification today sends KYC codes (`NATIONAL_ID`), but the document list uses
    `IDENTITY_CARD`. This is an existing defect, and this PR fixes it.
- **Caching is up to the app.** Neither endpoint returns `ETag` or `Cache-Control`
  (`cf-cache-status: DYNAMIC`).
- **Both environments return the same data.** For Kenya, production is byte-for-byte the same
  as sandbox on both endpoints.
- **Size.** The whole of Africa is about 45 KB for documents (`en-GB`) and 13 KB for ID types.

## Decisions

### D1 — The network call lives in each shell, behind a seam in `sample-ui`

`sample-ui` gets one new interface, `UseSmileIDSampleCatalogueSource`, with three calls:
`countries(family, locale, sandbox)`, `documents(country, locale, sandbox)` and
`idTypes(country, sandbox)`. The country picker needs its list before a country is chosen, so
`countries` reads `supported_id_types` with no country for the KYC family, and
`supported_documents?continent=AFRICA` for the document family. The document family's country list grows from 7 to
56 rows, which the picker's search already handles. Each shell implements it
with the HTTP client it already uses for job status. This is the same pattern as
`UseSmileIDSampleJobStatusSource`.

| Platform | Adapter | Client already in the shell |
|---|---|---|
| Android | `android/app/.../catalogue/RetrofitCatalogueSource.kt` | Retrofit + kotlinx.serialization (`status/UseSmileIDSampleStatusApi.kt`) |
| iOS | `ios/App/Sources/Catalogue/UseSmileIDSampleCatalogueApi.swift` | `URLSession`, 10-second bound (`Status/UseSmileIDSampleStatusApi.swift`) |
| Flutter | `flutter/app/lib/src/catalogue/use_smileid_sample_http_catalogue_source.dart` | `dart:io` `HttpClient` (`status/use_smileid_sample_http_job_status_source.dart`) |
| Expo | `expo/app/src/catalogue/use-smile-id-sample-catalogue-api.ts` | `fetch` (`status/use-smile-id-sample-status-api.ts`) |

This adds no dependencies. Each shell passes its source in where it already passes its job
status source:

- Android: `UseSmileIDSampleAppState.kt`
- iOS: `UseSmileIDSampleAppState.swift`
- Flutter: `use_smileid_sample_session_providers.dart`
- Expo: the matching provider

Rejected:

- **The call inside `sample-ui`.** The SDK repos' development samples compile `sample-ui`
  against SDK HEAD. Networking in the shared UI would run in eight app identities, and would
  break the rule that the shell owns the network.
- **Wait for the SDK to wrap the endpoints.** Nothing ships that today. Instead this is filed
  as an SDK finding: partners need the same lists, so the SDK should expose
  `supportedDocuments(country, locale)` and `supportedIdTypes(country)`. When that ships, each
  shell's adapter calls the SDK instead, and the seam stays the same.
- **The v1 `POST /v1/valid_documents` that v11 used.** It needs a signature, and it is the older
  API.

### D2 — The environment follows the linked token, and sandbox is the default

- With a live token session, the base URL is the session's environment. That comes from the
  token's `api_url` host, through `environmentFor()`, exactly as status refresh chooses it.
- With no token, the app uses sandbox.

Both endpoints are unauthenticated and currently return the same data, so no token is ever
sent. A missing token therefore never blocks the list.

Rejected: a separate environment switch. That would be one more control that could disagree
with the token.

### D3 — Fetch live on every run, as v11 did; no bundled list

The apps keep no copy of the lists. A document type or ID type that is added or removed on the
server shows up on the next run, with no app update and nobody maintaining a file.

- **When it fetches.** Once per run of the ID form: starting a product that needs ID details
  fetches that product's country list, and choosing a country fetches that country's list (D9).
  Results are reused only for the rest of that run, so reopening a sheet mid-form does not fetch
  again. The next run always asks the server again.
- **No cache on disk.** Nothing survives the run, so no saved copy can go stale unseen.
- **Offline.** A failed fetch is an error state with Retry (D9), not a fallback list. This costs
  nothing real: without the network the SDK cannot submit the job anyway, so a list that
  loaded offline would only lead to a failure one screen later.
- **Fixed data for device flows.** A new launch argument, `catalogue`, takes:
  - `live`, the default
  - `fixture`: the lists come from `spec/catalogue-fixture.json`, with no network (S8)
  - `unreachable`: every call fails at once

  Every device flow passes `fixture`, so no flow depends on the network. `unreachable` is how
  the error state is driven.
- **The fixture is not a snapshot.** It holds about a dozen rows chosen for the UI's cases, with
  real-looking codes, and each app reads it from `spec/` at build time. It changes only when the
  UI gains a case, never because the API changed.

Rejected:

- **A bundled snapshot of the API, refreshed by a script or a scheduled workflow.** New
  document types would need an app update, and the file would be one more thing to maintain.
- **A disk cache of the last good response.** It would show removed document types without
  saying so, and it is one more store to migrate on four platforms. Offline also gains nothing
  from it, because submission needs the network.
- **A cache for the whole process.** A long-running demo app would miss a change until it was
  killed. Once per run keeps the fetch count low and the data current.

### D4 — The state shape: data from the API, not enums

The enums `UseSmileIDSampleCountry` and `UseSmileIDSampleIdType` are replaced on all four
platforms. They live in `UseSmileIDSampleIdDetails.*` and in
`use_smileid_sample_id_details.dart` and `use-smile-id-sample-id-details.ts`. The new types:

- **`UseSmileIDSampleCountry(code, name)`.** The flag is computed from the ISO code using
  regional-indicator letters, so no table is needed.
- **`UseSmileIDSampleKycIdType(id, type, label, regex, requiredFields)`.** This is the KYC
  family. `id` follows S2.
- **`UseSmileIDSampleDocument(code, subType, name, hasBack, format)`.** This is the document
  family. `subType` is null except on a flattened sub-type row.
- **`UseSmileIDSampleCatalogue`**: `loading`, `ready(items)`, `failed(reason)` or `empty`. Each
  picker has one.
- **The product decides the family.**
  - Document Verification and Enhanced Document Verification read `supported_documents`.
  - Biometric KYC and Enhanced KYC read `supported_id_types`.
  - The country picker for a KYC product lists only countries that have ID types, so Rwanda
    no longer appears there.
- **What is saved.** `UseSmileIDSampleIdDetails` stores codes (country code, id-type id or
  document code, and the number), never whole objects.
  - After process death, Android's `Saver` and the other platforms' restore paths look the
    codes up again in the catalogue.
  - A code that no longer resolves clears that field, and does not crash.
  - Profiles do not store ID details, so profiles need no migration.

Rejected:

- **Keep the enums and let the API filter them.** An ID type the API adds would never appear.
- **One shared type for both families.** They have different fields (a regex against a back
  side) and different codes.

### D5 — Which ID types a KYC product offers

A type is listed only if the form can supply every field in its `required_fields`:

- the fields every type needs, which the SDK fills in
- `first_name` and `last_name`, from the user-details form

`dob` and `citizenship` are not collected, and the SDK's KYC parameters have no field for
either, so a type that needs one is left out (S9).

A type that needs `bank_code`, `session_id` or `operator` is left out too. Against the
2026-09-28 data the rule keeps 30 of 64 ID types. This rule sits in one pure function per
platform, and it runs on whatever the server returns, so a new type needs no app change. Its test cases live
in `spec/catalogue-rules.json`, so all four platforms check the same cases.

Rejected: listing everything and letting the server reject it. That sends a demo to a failure
that the form could have prevented.

### D6 — Document type, and how it feeds `DocumentCaptureConfig`

For the document products, the ID form gains a **DOCUMENT** trigger in place of the ID-type
trigger. It lists the country's API documents, with standalone sub-types such as the Green Book
as their own rows (S5).
Under it, a **Capture as** trigger offers four choices:

| Choice | `documentType` | `captureBothSides` |
|---|---|---|
| **Automatic** (the default) | Chosen from `format`: 7 → `SouthAfricaGreenBook`; 3 → `DocumentType.Passport`; anything else → `GenericDocument(displayName = name, hasBackSide = has_back)` | The API's `has_back`, for every row |
| **Green Book preset** | `SouthAfricaGreenBook` | `documentType.hasBackSide` |
| **Passport preset** | `Passport` | `documentType.hasBackSide` |
| **Custom** | `GenericDocument` built from four controls in a sheet: display name, back side (switch), orientation (landscape or portrait), and aspect ratio (off, 1.586 card, 1.309 passport or 0.748 booklet). The ratio becomes the `GenericDocument`'s `knownAspectRatio` | `documentType.hasBackSide` |

Rules that apply to every choice:

- `allowSkipBack` stays `true`, as it is today.
- The server always receives the document's code as `idType`. "Capture as" changes only how
  the photo is taken, never what is submitted. That separation is why the override can exist
  without sending the server a wrong type.
- The mapping is one pure function per platform, in each shell's flow-builder config:
  - Android: `FlowBuilderConfig.kt`
  - iOS: `FlowBuilderConfig.swift`
  - Flutter: `use_smileid_sample_flow_builder_config.dart`
  - Expo: `use-smile-id-sample-flow-builder-config.tsx`

Rejected:

- **Map `format` 5 and 6 to shapes of their own.** Each covers one document, and the SDK has no
  preset for either, so they stay generic until one exists.
- **Match on `code` instead of `format`.** A seaman's ID is `format` 3 but is not a passport,
  and the Green Book shares its code with the card.
- **Use the Passport preset's `hasBackSide` under Automatic.** It disagrees with the API, and
  the API is the source that says what the document is.
- **A separate Settings control for document type.** The backlog asks for it on the form, and
  its values depend on the chosen country.

### D7 — The ID-number hint and format check

The hint is computed from the regex, because the API gives no example:

1. Take the first alternative at the top level and inside each group.
2. Turn character classes into text: a digit class becomes `0`, a letter class `A`, a mixed
   class `A`, and a literal stays as it is.
3. Repeat each part: a bounded `{m,n}` uses `n`, `{m}` uses `m`, and `*`, `+` or `?` use the
   minimum, with a minimum of one for `+`.
4. The field shows "e.g. `<example>`". Examples:
   - `^[0-9]{11}$` → `00000000000`
   - Ghana card → `AAA-000000000-0`
5. If the regex uses anything outside this subset, the field shows "Enter your `<label>`".

Checking the number:

- The number is trimmed, then must match the whole regex before Continue is enabled.
- When a non-empty number does not match, the field shows an error, `sample_idnumber_error`,
  that repeats the example.
- Until an ID type is chosen, the field is disabled and says "Choose an ID type first", the
  same way the ID-type trigger waits for a country.

Test cases live in `spec/id-number-hints.json`: pairs of regex and expected hint, taken once
from the 2026-09-28 responses to cover the syntax the server uses. They test the algorithm, so
they change only when the algorithm does. Each platform's test asserts that:

1. the hint matches the expected hint,
2. every generated example matches its own regex, and
3. every case compiles with that platform's regex engine (Kotlin `Regex`,
   `NSRegularExpression`, Dart `RegExp`, JavaScript `RegExp`).

At runtime, a regex that fails to compile on the device never blocks anyone. The field shows
"Enter your `<label>`", checks nothing, and leaves the server to judge the number.

Rejected: a hand-written hint table. That is the hard-coded list again. Also rejected: no hint
at all. The backlog asks for one.

### D8 — `captureMode` and `allowGalleryUpload` in Settings

**Capture mode** is a Settings row with a `SelectTrigger`-style value, `sample_setting_capture_mode`.
It opens an option sheet with three rows, `sample_capture_mode_option_{auto|manual|autoWithFallback}`.
The default is `autoWithFallback` with the SDK's 10 seconds. There is no duration control.

**Gallery upload** is a `Switch` row, `sample_setting_gallery_upload`. It is off by default,
which is the SDK's default. Its supporting line says the system picker needs no permission.

How Settings changes:

- `UseSmileIDSampleSettings` today is a map of true/false values (`get`, `withSetting`, and the
  `Saver`). Capture mode becomes its own typed field, outside that map.
- Stored preferences gain one key per platform, and a missing key reads as the default.
- `components.json`'s `settingsToSdkMapping` gains both rows.

How it is checked:

- **Unit tests.** Each platform checks setting → `DocumentCaptureMode` or `allowGalleryUpload`.
- **The wire, in debug only.** Each shell adds a debug-only interceptor on the SDK's public hook
  (see [What the SDK does today](#what-the-sdk-does-today-checked-at-121-on-all-four-platforms)).
  It logs only `auto_capture_enabled`, `capture_both_sides` and `allow_gallery_upload` from the
  submission metadata, never images or personal data. On iOS, Loupe already shows the request.
- **Public device flows stop at the capture screen,** so the wire check is a manual debug run:
  capture a real document on sandbox and read the log (`adb logcat` or the Xcode console).
- **Release** is checked by what the screen does:
  - `manual`: the shutter shows at once.
  - `autoWithFallback`: the shutter shows after 10 seconds.
  - `auto`: no shutter within 15 seconds.
  - With gallery upload on, the gallery button is present.
- Release logs no traffic, and the interceptor is compiled into debug only.

Rejected:

- **Chucker, or another traffic-inspector dependency.** It adds a dependency, and it is not
  needed for three keys.
- **A new result-card field.** The public flows never reach submission.
- **A segmented control.** There is no such component in `components.json`, and adding one
  would mean designing it on four platforms.

### D9 — Loading UX: the reader should rarely see it

There are no design frames for any of this, and none are coming, so D9 is the design of record.
It is built from what the app and the design system already have. When the plan is deleted,
its reasoning moves to `docs/architecture.md`.

The form today is three calm controls and two sheets, and nothing on it waits. The design
system's rule is that an empty list is a normal state, not a failure (`EmptyState`), and the
only loading treatment the app ships is the Button's `loading` state. Loading the lists must fit
that: no full-screen spinner, no blocked form, no layout that jumps.

**1. Fetch ahead, so the wait happens while the reader is busy.**

| When | What starts |
|---|---|
| A product that needs ID details is tapped | `countries(family, locale)` for that product's family. The user-details form sits between, so the list is usually ready before the ID form appears |
| A country is chosen | That country's `idTypes` or `documents`, before the reader reaches the next trigger |
| The same key again in this session | Nothing. It comes from the memory cache (D3) |

A new `UseSmileIDSampleCatalogueStore` in `sample-ui` owns the fetching, the cache and the
cancellation, as the job store owns status refresh; screens only read its state. Leaving the
form cancels a fetch still in flight; changing country cancels the old country's fetch.

**2. The form never waits.**

- While a country's list is still loading, the ID-type (or DOCUMENT) trigger stays **enabled**.
  Its placeholder reads "Loading ID types…" (or "Loading documents…") in the trigger's existing
  muted placeholder style. It has no spinner, because the trigger is a control, not a status.
- Tapping it opens the sheet at once; the sheet shows the loading state below.
- Continue depends only on the fields. Once a list has loaded, nothing on the form waits on the
  network again.
- Changing country clears the ID type or document, as it does today. It keeps the typed number
  and checks it again against the next type's format (D7), so a mistaken country tap costs
  nothing.

**3. A sheet that opens before its data shows skeleton rows, not a spinner.**

- **Shape.** Six `OptionRow`-shaped placeholders at the row's own 44 height. Country rows carry
  a 19 circle where the flag goes. Each label bar has a different width (72, 48, 64, 56, 80, 40
  per cent) so the rows do not read as a table.
- **Colour.** The design system's `skeleton.bg` and `skeleton.highlight` tokens, which the four
  apps vendor but do not use yet.
- **Motion.** A pulse between the two colours every `skeletonDuration` (350 ms), with no sweep.
  When the platform asks for reduced motion, the rows are static.
- **Timing.** Rows appear only after 300 ms, so a fast answer never flashes. Once shown, they
  stay for at least 400 ms, so they never flicker.
- **Search.** The sheet's `SearchField` is visible but disabled until the rows arrive: there is
  nothing to filter yet.
- **Accessibility.** The skeleton container (`sample_catalogue_loading`) is one element that
  announces "Loading countries" (or ID types, or documents). The placeholder rows are hidden
  from the accessibility tree.
- **Arrival.** When the data arrives, the rows replace the skeleton in place, with no animation
  beyond the platform's default content change. The sheet keeps its height, which is already
  content height (`BottomSheet.metrics.openHeight`).

**4. A failure is a quiet state with a way out, not an alert.**

| Case | Treatment |
|---|---|
| The fetch fails or passes the 10-second timeout | The sheet shows `EmptyState` with supporting text and a **Retry** text action (`sample_catalogue_error`, `sample_catalogue_retry`): "Couldn't load ID types" (or countries, or documents), "Check your connection, then try again". While Retry runs, the skeleton rows come back under the same timing rules. On the form, the trigger's placeholder goes back to "Select ID type", so the form never looks stuck |
| The country has no entries the form can use | `EmptyState` with supporting text, with no Retry, because retrying cannot change the answer: "No ID types for Rwanda", "Choose another country". The existing `sample_idtype_empty`, or `sample_document_empty` |

Rejected:

- **A Toast for the failure.** Toasts here are brief confirmations with an undo. The failure
  lasts as long as the sheet is open, and it needs a Retry that stays reachable.
- **A spinner in the sheet, or a disabled trigger while loading.** A spinner reads as "stuck"
  on a slow connection. A disabled trigger hides the one thing the reader wants to do next.
- **Pull to refresh inside the sheet.** It has been ruled out for the list, and a gesture that
  exists in one sheet only would not be found. Retry covers the case.

## Spec changes

The whole list, for S1–S9:

- **`test-ids.json`, new ids:**
  - `sample_document_trigger`, `sample_document_sheet`, `sample_document_search`,
    `sample_document_option` (suffixed with the code, and `_<subType>` on a sub-type row, e.g. `IDENTITY_CARD_green_book`),
    `sample_document_empty`
  - `sample_capture_as_trigger`, `sample_capture_as_option` (suffixed
    `automatic|greenBook|passport|custom`)
  - `sample_custom_document_sheet`, `sample_custom_document_name`,
    `sample_custom_document_back_side`, `sample_custom_document_orientation`,
    `sample_custom_document_aspect_ratio`, `sample_custom_document_done`
  - `sample_idnumber_error`
  - `sample_catalogue_loading`, `sample_catalogue_error`, `sample_catalogue_retry`
  - `sample_setting_capture_mode`, `sample_capture_mode_sheet`, `sample_capture_mode_option`
    (suffixed), `sample_setting_gallery_upload`
- **`test-ids.json`, changed descriptions:** `sample_idtype_option` (S1, S2),
  `sample_idtype_empty` (the country has no types that the form can satisfy).
- **`screens.json`, `kycIdForm`:**
  - It gains the states `documentSelected`, `idNumberInvalid` and `catalogueError`, all marked `"design": "in-repo"`.
  - `appliesTo` and `fieldDependency` are rewritten for S4 and the document trigger.
- **`screens.json`, new sheets:** `documentPickerSheet`, `captureAsSheet`,
  `customDocumentSheet` and `captureModeSheet`, each with `default`.
- **`screens.json`, the three fetching sheets** (`countryPickerSheet`, `idTypePickerSheet` and
  `documentPickerSheet`): gain `loading`, `error` and `empty` (D9), all marked
  `"design": "in-repo"`.
- **`screens.json`, `settings`:** gains the two rows' ids.
- **`components.json`:**
  - `settingsToSdkMapping` gains "Capture mode" and "Gallery upload".
  - `OptionRow` gains a `skeleton` state (D9), which uses the `skeleton.*` tokens.
  - `SelectTrigger` gains a `loading` state: muted placeholder, still enabled.
  - No new component: the new screens reuse `SelectTrigger`, `OptionRow`, `BottomSheet`,
    `Switch`, `TextInput`, `EmptyState` and `SettingRow`.
- **`launch-args.json`:** gains `catalogue` (`live` | `fixture` | `unreachable`, default
  `live`).
- **New data files:** `spec/catalogue-fixture.json`, `spec/catalogue-rules.json` and
  `spec/id-number-hints.json`. All three are test inputs, not copies of the API. `spec/README.md`'s file table lists all three.
- **`scenarios.json`:** no change. The capture options are Settings, not scenarios.

## Per platform

Every platform follows the same six steps:

1. Replace the catalogue enums (D4).
2. Add the catalogue seam, the store and the picker states (D1, D3, D9).
3. Add the document trigger and the "Capture as" sheet (D6).
4. Add the hint and the format check (D7).
5. Add the Settings rows (D8).
6. Update the flow-builder mapping.

Then add the spec checks for the new ids, the launch argument and the fixture.

**Android** is the reference.

- `sample-ui`:
  - `state/UseSmileIDSampleIdDetails.kt`, `UseSmileIDSampleForms.kt`, `UseSmileIDSampleSettings.kt`
  - `data/UseSmileIDSampleCatalogueSource.kt` and `data/UseSmileIDSampleCatalogueStore.kt`, which
    are new
  - `components/UseSmileIDSampleOptionRow.kt` (the skeleton state)
  - `screens/KycIdFormScreen.kt`, `CountryPickerSheet.kt`, `IdTypePickerSheet.kt`
  - `DocumentPickerSheet.kt`, `CaptureAsSheet.kt`, `CustomDocumentSheet.kt` and
    `CaptureModeSheet.kt`, which are new
  - `SettingsScreen.kt`, `UseSmileIDSampleTestIds.kt`
- `app`:
  - `flow/FlowBuilderConfig.kt`, `FlowLaunchSnapshot.kt`
  - `catalogue/RetrofitCatalogueSource.kt`, which is new
  - a debug `WireProbeInterceptor.kt`
  - `UseSmileIDSampleAppState.kt`, and the launch-argument parser
- Tests:
  - `UseSmileIDSampleTestIdsSpecTest`, `UseSmileIDSampleLaunchArgsSpecTest`
  - new: `CatalogueRulesSpecTest`, `IdNumberHintSpecTest`, and a mapping test for D6, next to
    `FlowJourneyStepsTest`
  - Roborazzi goldens in `FormGoldenTest` and the Settings goldens, light and dark, for every
    new state and sheet
  - the font-scale predicate for the form with its error line, for the custom-document sheet,
    and for the error state
  - store tests with a fake source and a test clock: fetch ahead, cancel on country change,
    the 300 ms delay and 400 ms minimum, the 10-second timeout, and Retry
  - goldens for each sheet's `loading`, `error` and `empty`, light and dark
- Maestro:
  - `settings.yaml` gains both rows.
  - A new `document-options.yaml` covers:
    - document type, then "Capture as", then SDK mount
    - Green Book → `si_instructions_screen`, with no back-instructions screen after capture entry
    - capture mode → shutter timing
  - `launch-args.yaml` covers `catalogue=unreachable` → error state → Retry.
  - `deep-links.yaml` and every flow that uses the form gain `catalogue=fixture`.
  - Run on a physical Android device over USB, debug and release.

**iOS**

- `SampleUI`:
  - `State/UseSmileIDSampleIdDetails.swift`, `UseSmileIDSampleSettings.swift`
  - `Data/UseSmileIDSampleCatalogueSource.swift`, which is new
  - `Screens/KycIdFormScreen.swift`, `CountryPickerSheet.swift`, `IdTypePickerSheet.swift`, plus
    the four new sheets
  - `SettingsScreen.swift`, `UseSmileIDSampleTestIds.swift`
- `App`:
  - `Flow/FlowBuilderConfig.swift`, `FlowLaunchSnapshot.swift`
  - `Catalogue/UseSmileIDSampleCatalogueApi.swift`, which is new
  - `Launch/UseSmileIDSampleLaunchArguments.swift`, `State/UseSmileIDSampleAppState.swift`
- Tests:
  - `UseSmileIDSampleIdDetailsTest`, `UseSmileIDSampleLaunchArgumentsSpecTest`, the id-usage
    check, new hint and rules spec tests, and goldens for each new state, light and dark
- XCUITest:
  - `UseSmileIDSampleFlowUITests` and `UseSmileIDSampleNavigationUITests` pass
    `catalogue=fixture`.
  - A new `UseSmileIDSampleDocumentOptionsUITests` mirrors the Android flow.
  - The simulator has no camera, so the flows stop at SDK mount. Checking shutter timing needs
    a device, which is outside this run.
  - Fix on the way: `testEnhancedKycOnALiveSessionReachesATerminalResult` taps
    `sample_idtype_option_nationalId`, but the id is `sample_idtype_option_NATIONAL_ID`. It also
    types `AO12345678`, which Kenya's regex rejects. It only runs with a live session, which is
    why this has not shown up.

**Flutter**

- `sample_ui`:
  - `state/use_smileid_sample_id_details.dart`, `use_smileid_sample_settings.dart`
  - `data/use_smileid_sample_catalogue_source.dart`, which is new
  - `data/use_smileid_sample_settings_repository.dart`
  - `screens/use_smileid_sample_kyc_form_screen.dart`, `use_smileid_sample_picker_sheets.dart`
    (plus the four new sheets), `use_smileid_sample_settings_screen.dart`
  - `use_smileid_sample_test_ids.dart`
- `app`:
  - `flow/use_smileid_sample_flow_builder_config.dart`, `use_smileid_sample_flow_launch_snapshot.dart`
  - `catalogue/use_smileid_sample_http_catalogue_source.dart`, which is new
  - `data/use_smileid_sample_preferences_settings_repository.dart`
  - `state/use_smileid_sample_forms.dart`, and the session providers
- Tests: the spec tests under `sample_ui/test/spec/`, `forms_golden_test.dart` and
  `settings_screen_golden_test.dart`, and the predicate envelope.
- Maestro: `flutter/maestro/sdk-flow.yaml` gains `catalogue=fixture` and the document step.
- Pixel goldens are recorded on the CI runner, not locally.

**Expo**

- `sample-ui`:
  - `state/use-smile-id-sample-id-details.ts`, `use-smile-id-sample-forms-store.ts`,
    `use-smile-id-sample-settings.ts`, `use-smile-id-sample-settings-store.ts`
  - `data/use-smile-id-sample-catalogue-source.ts`, which is new
  - `screens/kyc-id-form-screen.tsx`, `country-picker-sheet.tsx`, `id-type-picker-sheet.tsx`,
    plus the four new sheets, and `settings-screen.tsx`
  - `use-smile-id-sample-test-ids.ts`, `index.ts`
- `app`:
  - `flow/use-smile-id-sample-flow-builder-config.tsx`, `use-smile-id-sample-flow-launch-snapshot.ts`
  - `catalogue/use-smile-id-sample-catalogue-api.ts`, which is new
- Tests:
  - `use-smile-id-sample-test-ids-spec.test.ts`, which also checks the reverse direction
  - the launch-argument spec test
  - new hint and rules tests
  - `use-smile-id-sample-font-scale.test.tsx`, and the pixel goldens, which are recorded on the
    CI runner
- Maestro: `expo/maestro/sdk-flow.yaml` and `deep-links.yaml` gain `catalogue=fixture` and the
  document step.

## Order of work in the one PR

Step 0 must pass before any code is written. The rest are one commit each, or a few.

| Step | Work | Can check locally | Only CI can check |
|---|---|---|---|
| 0 | On a physical Android device, with current `main` in debug, confirm what the SDK does:<br>• Passport captures a back side<br>• Kenya National ID (today a `GenericDocument`) captures a back side<br>• whether the server rejects an Enhanced KYC job (no capture needed) with no date of birth, on a sandbox token (S9)<br>The gallery picker cannot be checked on `main`, because nothing sets `allowGalleryUpload`. It moves to step 2 | Everything | — |
| 1 | `spec/` edits and the three data files | The spec-validation tests fail on all four platforms, which is expected until they catch up | — |
| 2 | Android, in full | `android/verify.sh`, Maestro on a physical Android device in debug and release, and one hand run with `catalogue=live` against sandbox | — |
| 3 | iOS | `ios/verify.sh`, in slices (`checks`, then UI), and XCUITest on the simulator | — |
| 4 | Flutter | `flutter/verify.sh checks`, and Maestro on a physical Android device | Pixel goldens (take them from `flutter-goldens-recorded`) |
| 5 | Expo | `expo/verify.sh`, `native`, and Maestro on a physical Android device | Pixel goldens (take them from `expo-goldens-recorded`) |
| 6 | The manual debug wire check (D8), on a physical Android device for Android | `auto_capture_enabled`, `capture_both_sides` and `allow_gallery_upload` in the log for each mode | — |

`spec/` goes red on all four platforms after step 1 and green again after step 5. That is why
this is one PR and not four.

## Risks and unknowns

| Risk | How to retire it |
|---|---|
| The SDK behaves differently when `captureBothSides` and `hasBackSide` disagree | Checked in source on all four platforms: it is an AND. Step 0 confirms it on a device. D6 makes the two agree, so the sample never depends on the difference |
| The Passport preset's `hasBackSide = true` does not match the API | Automatic sets `captureBothSides` from `has_back`. File an SDK finding to confirm the preset |
| The API is down during a demo | The error state with Retry (D9). The SDK could not submit without the API anyway. A demo that must run offline up to the capture screen can pass `catalogue=fixture` on purpose |
| A country has no supported documents, or no ID types the form can satisfy | The existing empty states, with text that says which case it is. Covered by a unit test and a golden using a fake source; no device flow needed |
| Right-to-left names under `ar-EG` | Only document and country names are translated, and the rows lay out using each platform's text direction. Add one `ar-EG` golden for the document sheet on each platform, and a font-scale predicate run. The app does not flip its own layout unless `appLocale` is Arabic, and that is out of scope |
| Server regexes use syntax that one platform's engine does not support | D7's cases cover today's syntax on every engine. A regex that fails to compile at runtime makes the field skip its check, and never blocks anyone |
| A new server field or document shape arrives | Readers ignore unknown keys, as status refresh already does. A new `format` value falls back to a generic card, and a new `required_fields` entry drops that type until the form can supply it. None of these needs an app update to stay safe |
| The server rejects an Enhanced Document Verification document (S6) | The result card shows it. Revisit this if the v3 API adds a supported list for this product |
| The SDK publishes no ids for the shutter or the gallery button | Flows match the SDK's accessibility labels until an SDK release publishes ids. SDK finding |
| The design system's dark `skeleton.highlight` is `#eaecf0`, the same as light, so a dark pulse would flash near-white | Record it as a delta in `spec/design-tokens.json` and report it to the design system. Until it is fixed, dark mode pulses `skeleton.bg` against `color.surface-muted`, which is a semantic token |
| A slow network makes the skeleton look stuck | The 10-second timeout ends in the error state, never an endless skeleton. A Maestro step with `catalogue=slow` could cover it, but that is a fourth launch value, so it is left out unless review asks for it |
| iOS shutter timing cannot be checked on the simulator | It needs a device run, which is not in this run's scope. Say so in the PR |

## Findings to file (not fixed here)

**SDK, all four platforms:**

1. Expose `supportedDocuments` and `supportedIdTypes`.
2. The `Passport` preset's `hasBackSide` does not match the API.
3. The metadata's `capture_both_sides` reports the setting, not what was applied.
4. The manual shutter and the gallery button have no published ids.

**API reference** (`v3-services.yaml`):

- `example` is described as sample numbers but holds descriptions.
- `format` and `sub_types` are not documented.
- Country and continent together is accepted, and the country wins.
- An unsupported locale silently falls back to `en-GB`.
- The continent list says `NORTH AMERICA`, but the server error says `NORTH_AMERICA`.
- There is no v3 list of documents supported for Enhanced Document Verification.

## Backlog edits this PR makes

- **Remove** "Exercise the SDK's document-capture options". This PR does it.
- **Remove** "Pull to refresh on the verifications list".
  It is ruled out, because jobs are stored on the device and no endpoint lists a partner's
  jobs. The list's `refreshing` state is recorded in `spec/README.md`'s spec-debt table.
- **Add**, if not fixed along the way: iOS shutter-timing coverage on a device, and the SDK id
  swap for the shutter and gallery once an SDK release publishes them.
