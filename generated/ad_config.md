# Ad + IAP configuration

**Fill in the blanks below and hand this file back.** Nothing else is needed —
the wiring is already built against Google's test IDs, so bringing this live is
a constants swap, not a code change.

---

## The one distinction that trips everyone up

AdMob issues two different kinds of identifier and they look almost identical:

| | Separator | Example | Where it goes |
|---|---|---|---|
| **App ID** | **tilde `~`** | `ca-app-pub-1234567890123456~1234567890` | `AndroidManifest.xml` |
| **Ad unit ID** | **slash `/`** | `ca-app-pub-1234567890123456/1234567890` | Dart source |

Both start `ca-app-pub-` followed by a **16-digit** publisher number. After the
separator comes a **10-digit** id.

**If you take one thing from this page:** a `~` is an app, a `/` is an ad unit.
Putting a unit ID in the manifest makes the app crash on launch with
`Invalid application ID`. Putting an app ID in Dart makes ads silently never
load, which is far worse because nothing tells you.

---

## 1. AdMob App IDs → `AndroidManifest.xml` / `Info.plist`

Found in AdMob under **Apps → [your app] → App settings**. One per platform;
they are different values even for the same game.

```
ANDROID_ADMOB_APP_ID = ca-app-pub-9242904787767394~3712054804

IOS_ADMOB_APP_ID     = ca-app-pub-9242904787767394~8772809792
```

I put the Android one into `android/app/src/main/AndroidManifest.xml` as:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-...~..."/>
```

The iOS one goes into `ios/Runner/Info.plist` under `GADApplicationIdentifier`.
Not shipping in v1, but I will set it so it is never a surprise later.

---

## 2. Ad unit IDs → Dart (`lib/services/ads/ad_ids.dart`)

Created in AdMob under **Apps → [your app] → Ad units → Add ad unit**. Pick the
format shown in the "Create as" column — the format is not editable afterwards.

### Android

```
ANDROID_INTERSTITIAL_LEVEL_COMPLETE = ca-app-pub-9242904787767394/2104344149
ANDROID_REWARDED_HINT               = ca-app-pub-9242904787767394/2509714423
ANDROID_REWARDED_EXTRA_TUBE         = ca-app-pub-9242904787767394/9813489373
ANDROID_REWARDED_LEVEL_SKIP         = ca-app-pub-9242904787767394/2046679999
```

### iOS

```
IOS_INTERSTITIAL_LEVEL_COMPLETE = ca-app-pub-9242904787767394/6698195277
IOS_REWARDED_HINT               = ca-app-pub-9242904787767394/1496955005
IOS_REWARDED_EXTRA_TUBE         = ca-app-pub-9242904787767394/4833564783
IOS_REWARDED_LEVEL_SKIP         = ca-app-pub-9242904787767394/1336233558
```

### Create them as

| Slot | Create as | Suggested AdMob name |
|---|---|---|
| Interstitial (post level complete) | **Interstitial** | `pourfect_interstitial_level_complete` |
| Rewarded — hint | **Rewarded** | `pourfect_rewarded_hint` |
| Rewarded — extra tube | **Rewarded** | `pourfect_rewarded_extra_tube` |
| Rewarded — level skip | **Rewarded** | `pourfect_rewarded_level_skip` |

**Three separate rewarded units, not one shared unit.** They serve the same
format, but separate units give per-placement revenue and fill-rate figures in
AdMob — which is the only way to find out that, say, level-skip earns nothing
and should be dropped. Reusing one unit throws that data away permanently and
you cannot reconstruct it later.

For rewarded units AdMob asks for a **reward amount and item**. The app ignores
both and grants its own reward, but the fields are required:

- Reward amount: `1`
- Reward item: `reward`

---

## 3. In-app purchase

### Google Play Console

**Monetize → Products → In-app products → Create product.** Must be a
**one-time** product, not a subscription.

```
PLAY_REMOVE_ADS_PRODUCT_ID = _________________________
```

- Suggested id: `remove_ads` — lowercase, no spaces. **It can never be changed
  or reused once created**, so pick it deliberately.
- Price: **$1.99** (Play converts per region).
- Status must be **Active**, or the app sees no product and the store screen
  shows nothing.

> The product must exist and be Active **before** a build can list it, and it
> only becomes purchasable for accounts on a testing track. This is a normal
> part of closed testing — it does not block the upload.

### App Store — leave blank for now

```
APPSTORE_REMOVE_ADS_PRODUCT_ID = _________________________
```

### Play Billing license key — probably not needed

```
PLAY_LICENSE_KEY = _________________________________________________
```

Found under **Monetize → Monetization setup → Licensing**. It is a long base64
RSA public key, not a `ca-app-pub-` value.

**You most likely do not need this.** It is only used for verifying purchase
signatures *on the device*, which is the weak way to do it — the app trusts
whatever the client says. We are verifying purchases **server-side** through the
Play Developer API using the service account already in the backend, which is
both stronger and what the stage-5 plan called for. Leave this blank unless I
come back and ask.

---

## 4. Test device (optional but worth it)

While testing, real ads can be replaced with test ads on your own phone without
changing any IDs. AdMob logs the id on first ad load:

```
I/Ads: Use RequestConfiguration.Builder().setTestDeviceIds(Arrays.asList("33BE2250B43518CCDA7DE426D04EE231"))
```

```
ANDROID_TEST_DEVICE_ID = 245721C02AABB0F5FDB14764DD880B29
```

**Never tap your own live ads on a device that is not registered as a test
device.** Google treats it as click fraud and suspends AdMob accounts for it,
which would be an expensive way to end this project.

---

## What happens when you hand this back

1. I replace the placeholders in `lib/services/ads/ad_ids.dart` and the
   `AndroidManifest.xml` meta-data.
2. `flutter test test/services` re-runs the frequency-cap tests — those are
   independent of the IDs and already pass.
3. I build, install, and confirm on your A24 that a **real** interstitial and a
   **real** rewarded video load and that the reward only lands after the video
   completes.
4. The four ad analytics events then join the other seven in DebugView.

## Until then

The app builds and runs on **Google's official test IDs**, which serve a real ad
filled with placeholder creative. A test ad is always labelled **"Test Ad"**
across the top — that label is how you know the plumbing is right. If you see an
ad without it before the real IDs are in, something is misconfigured and it
should be stopped immediately.
