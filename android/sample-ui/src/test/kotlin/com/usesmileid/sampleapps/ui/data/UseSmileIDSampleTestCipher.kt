package com.usesmileid.sampleapps.ui.data

/** Robolectric has no Android Keystore, so this reversible stand-in seals in unit tests. */
internal object UseSmileIDSampleTestCipher : UseSmileIDSampleCipher {
    override fun seal(plain: String) = "sealed:" + plain.reversed()
    override fun open(sealed: String) = sealed.removePrefix("sealed:").takeIf { it != sealed }?.reversed()
}
