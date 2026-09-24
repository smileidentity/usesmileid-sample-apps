package com.usesmileid.sampleapps.ui.golden

import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfile
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfiles
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleProfilesRecord
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails

/** Shared because the settings row and the profiles list must draw the same profile in the same hue. */
internal object ProfileFixtures {

    /** What the new-profile sheet builds: an organisation, both names, and nothing else. */
    val Created = UseSmileIDSampleProfile(
        id = "p-4",
        organisation = "Sahara Pay",
        defaults = UseSmileIDSampleUserDetails(firstName = "Ngozi", lastName = "Eze"),
    )

    /** The design's three, so these goldens stay the Figma boards; a plain launch is [None]. */
    val Seeded = UseSmileIDSampleProfiles(UseSmileIDSampleProfilesRecord(UseSmileIDSampleProfiles.fixtures()))

    val None = UseSmileIDSampleProfiles()

    val WithCreated = UseSmileIDSampleProfiles(UseSmileIDSampleProfilesRecord(UseSmileIDSampleProfiles.fixtures() + Created))
}
