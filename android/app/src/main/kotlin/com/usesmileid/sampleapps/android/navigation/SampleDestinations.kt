package com.usesmileid.sampleapps.android.navigation

import androidx.compose.runtime.Composable
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.RootGraph
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.usesmileid.sampleapps.ui.screens.CountryPickerSheet as CountryPickerContent
import com.usesmileid.sampleapps.ui.screens.IdTypePickerSheet as IdTypePickerContent
import com.usesmileid.sampleapps.ui.screens.KycIdFormScreen as KycIdFormContent
import com.usesmileid.sampleapps.ui.screens.NewProfileSheet as NewProfileContent
import com.usesmileid.sampleapps.ui.screens.ProductsScreen as ProductsContent
import com.usesmileid.sampleapps.ui.screens.ProfileConfigScreen as ProfileConfigContent
import com.usesmileid.sampleapps.ui.screens.ProfileSwitchSheet as ProfileSwitchContent
import com.usesmileid.sampleapps.ui.screens.ProfilesScreen as ProfilesContent
import com.usesmileid.sampleapps.ui.screens.ScanTokenScreen as ScanTokenContent
import com.usesmileid.sampleapps.ui.screens.ScenarioDrawerSheet as ScenarioDrawerContent
import com.usesmileid.sampleapps.ui.screens.SettingsScreen as SettingsContent
import com.usesmileid.sampleapps.ui.screens.UserDetailsScreen as UserDetailsContent
import com.usesmileid.sampleapps.ui.screens.VerificationDetailsScreen as VerificationDetailsContent
import com.usesmileid.sampleapps.ui.screens.VerificationsScreen as VerificationsContent

/**
 * The Android binding of `spec/routes.json`, in the order the route table lists it.
 *
 * Each destination is a thin wrapper: the shell owns the route, its typed arguments and its deep
 * link; `sample-ui` owns what the screen looks like. That split is what lets an SDK repo compile
 * the same `sample-ui` into its own development sample with its own identity and its own routes.
 *
 * Function names are load-bearing — KSP names each generated object after the function, so these
 * are what the `platform.android` column of the route table refers to. `sample-ui` screens are
 * imported under aliases so the two never shadow each other; the same simple name here would
 * recurse instead of delegating.
 *
 * Arguments are declared as composable parameters so KSP generates the typed
 * `…Destination(productId = …)` call. There are no hand-built string routes anywhere, and the
 * deep-link patterns come from `spec/routes.json` verbatim.
 *
 * Sheet routes (`countryPicker`, `idTypePicker`, `profileSwitch`, `newProfile`,
 * `scenarioDrawer`) are real routes here — deep-linkable and assertable, which is what the
 * navigation contract requires — but they are still pushed rather than presented. The native
 * sheet presentation lands with the screens themselves.
 */

@Destination<ProductsGraph>(start = true, deepLinks = [DeepLink(uriPattern = SampleDeepLinks.PRODUCTS)])
@Composable
fun ProductsScreen() = ProductsContent()

@Destination<VerificationsGraph>(start = true, deepLinks = [DeepLink(uriPattern = SampleDeepLinks.VERIFICATIONS)])
@Composable
fun VerificationsScreen() = VerificationsContent()

@Destination<SettingsGraph>(start = true, deepLinks = [DeepLink(uriPattern = SampleDeepLinks.SETTINGS)])
@Composable
fun SettingsScreen() = SettingsContent()

/** Also the post-submission landing route: on a result the flow and both forms are replaced by it. */
@Destination<VerificationsGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.VERIFICATION_DETAILS)])
@Composable
fun VerificationDetailsScreen(jobId: String) = VerificationDetailsContent(jobId = jobId)

/** The Consent Details Form. Shown for every product, before the SDK flow starts. */
@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.CONSENT_DETAILS_FORM)])
@Composable
fun ConsentDetailsFormScreen(productId: String) = UserDetailsContent(productId = productId)

/** Only for products whose spec entry sets `needsIdDetails`. */
@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.ID_DETAILS_FORM)])
@Composable
fun IdDetailsFormScreen(productId: String) = KycIdFormContent(productId = productId)

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.COUNTRY_PICKER)])
@Composable
fun CountryPickerSheet(productId: String) = CountryPickerContent(productId = productId)

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.ID_TYPE_PICKER)])
@Composable
fun IdTypePickerSheet(productId: String) = IdTypePickerContent(productId = productId)

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.PROFILE_SWITCH)])
@Composable
fun ProfileSwitchSheet() = ProfileSwitchContent()

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.PROFILES)])
@Composable
fun ProfilesScreen() = ProfilesContent()

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.PROFILE_CONFIG)])
@Composable
fun ProfileConfigScreen(profileId: String) = ProfileConfigContent(profileId = profileId)

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.NEW_PROFILE)])
@Composable
fun NewProfileSheet() = NewProfileContent()

@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.SCAN_TOKEN)])
@Composable
fun ScanTokenScreen() = ScanTokenContent()

/**
 * A debug affordance with no design frame, deep-linkable so a flow can open it directly rather
 * than reproducing a hidden gesture.
 */
@Destination<RootGraph>(deepLinks = [DeepLink(uriPattern = SampleDeepLinks.SCENARIO_DRAWER)])
@Composable
fun ScenarioDrawerSheet() = ScenarioDrawerContent()
