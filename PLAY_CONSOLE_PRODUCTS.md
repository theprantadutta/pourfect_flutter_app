# Play Console: products and store setup to do

Everything Pourfect sells or relies on in Play Console. **Monetization opens
only after the first production release**, so this is the checklist for that
day. The app and the API already handle all of it, so creating the products
is the only step left.

Full billing setup (service account, Pub/Sub, RTDN, testing):
`../pourfect-dotnet-api/docs/PLAY_BILLING.md`.

## In-app products (one-time, non-consumable)

Play Console → Pourfect → **Monetize → Products → In-app products**.

The IDs must be **exactly** as written. A product ID can never be changed or
reused once created. The app (`IapIds` in `lib/services/ads/ad_ids.dart`) and
the API (`ProductCatalogue`) both allowlist these two and nothing else.

| Product ID | Name | What it gives | Price | Status |
|---|---|---|---|---|
| `remove_ads` | Remove Ads | No ads between levels, forever. Rewarded videos stay available by choice. | you decide | ☐ create ☐ price ☐ activate |
| `skin_pack` | Skin pack | Ball skins Marble, Pearl and Checker, plus tube themes Wood and Lilac | you decide | ☐ create ☐ price ☐ activate |

Each product is its own entitlement: refunding or transferring one never
touches the other.

## Subscriptions

None. Nothing in Pourfect is sold as a subscription. The API ignores
subscription notifications.

## Consumables

None. Hint credits, extra-tube credits, streak freezes and star-chest rewards
are all earned by playing or by rewarded videos, never bought.

## Rewarded video placements (AdMob, not Play Console)

| Placement | Ad unit used today |
|---|---|
| Hint | its own unit (`rewardedHint`) |
| Extra tube | its own unit (`rewardedExtraTube`) |
| Streak freeze | **shares the spare level-skip unit** (`rewardedStreakFreeze`) |
| Double a star chest | **shares the spare level-skip unit** (`rewardedChestDouble`) |

Optional: create two dedicated rewarded units in AdMob for the streak freeze
and the chest double, so the AdMob reports name them. Then put their IDs in
`lib/services/ads/ad_ids.dart`. Nothing breaks if you don't.

## After the first production release

1. ☐ Create, price and activate both products above.
2. ☐ Play Console → Users and permissions: the service account
   `pourfect-play-verify@pourfect-c64ea.iam.gserviceaccount.com` has **View
   financial data** and **Manage orders and subscriptions**.
3. ☐ Monetization setup → Real-time developer notifications: topic
   `projects/pourfect-c64ea/topics/pourfect-play-rtdn`, **All notifications**,
   then press **Send test notification** and check the API log.
4. ☐ Setup → License testing: add your tester accounts.
5. ☐ Buy each product with a tester. The dashboard's Purchases page shows the
   purchase tagged "test". Then refund it from Order management; the purchase
   becomes "voided" and the item disappears within seconds.
