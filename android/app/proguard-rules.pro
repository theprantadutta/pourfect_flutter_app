# R8 keep rules.
#
# These exist because of a RELEASE-ONLY crash: the app died at launch with
#
#   Unable to get provider androidx.startup.InitializationProvider
#   Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
#
# google_mobile_ads pulls in WorkManager, which is backed by Room. Room
# instantiates its generated `*_Impl` database class BY NAME at runtime, so R8
# sees no reference to it, renames it, and the lookup fails. Debug builds are
# not minified, so this is invisible until a release build — which is precisely
# the build that reaches players.

# --- WorkManager / Room -----------------------------------------------------
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-dontwarn androidx.work.**

# Room resolves the generated implementation by name; keeping the base class
# alone is not enough.
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Entity class * { *; }
-keep @androidx.room.Dao class * { *; }
-dontwarn androidx.room.paging.**

# androidx.startup discovers initializers reflectively from the manifest.
-keep class androidx.startup.** { *; }
-keep class * implements androidx.startup.Initializer { *; }

# --- Google Mobile Ads ------------------------------------------------------
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# --- Play Billing -----------------------------------------------------------
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# --- Flutter deferred components (referenced only from the engine) ----------
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
