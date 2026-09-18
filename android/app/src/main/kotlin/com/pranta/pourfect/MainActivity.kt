package com.pranta.pourfect

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

/**
 * Reports the certificate this build is actually signed with.
 *
 * Google Play Services validates the signing certificate against the OAuth
 * clients registered for the package, so a fingerprint missing from the
 * Firebase console is precisely why Google sign-in works in a debug build and
 * fails in a release one. That failure surfaces as a *cancellation* — the
 * chooser closes immediately — which is indistinguishable from the player
 * pressing back, so the app cannot tell the difference and neither can the log.
 *
 * Reading it at runtime removes the guessing. Three certificates are in play
 * and each produces a different fingerprint:
 *
 *  - the debug keystore, for anything `flutter run` installs
 *  - the upload keystore, for a release APK built and installed directly
 *  - Play's own app signing key, for anything downloaded from Play, because
 *    Play re-signs every artifact it distributes
 *
 * All of them must be registered. This prints whichever one is really there.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pourfect/diagnostics",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "signingSha1" -> result.success(signingSha1())
                else -> result.notImplemented()
            }
        }
    }

    /**
     * The SHA-1 of the signing certificate, colon-separated and upper case —
     * the same shape the Firebase console shows, so the two can be compared by
     * eye without reformatting either.
     *
     * Returns null rather than throwing. This is a diagnostic; it must never
     * be the reason a launch fails.
     */
    private fun signingSha1(): String? = try {
        val certificate = firstSigningCertificate()
        certificate?.let {
            MessageDigest.getInstance("SHA-1")
                .digest(it)
                .joinToString(":") { byte -> "%02X".format(byte) }
        }
    } catch (error: Throwable) {
        null
    }

    @Suppress("DEPRECATION")
    private fun firstSigningCertificate(): ByteArray? {
        // GET_SIGNING_CERTIFICATES replaced GET_SIGNATURES in API 28 and is the
        // only one that reports a rotated key correctly. minSdk here is below
        // that, so both paths are kept rather than assuming the new one.
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val info = packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNING_CERTIFICATES,
            )
            info.signingInfo?.apkContentsSigners?.firstOrNull()?.toByteArray()
        } else {
            val info = packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNATURES,
            )
            info.signatures?.firstOrNull()?.toByteArray()
        }
    }
}
