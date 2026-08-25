# Hamptons Burgers

Native SwiftUI iOS app for **Hamptons Burgers**. Ordering, payment, guest accounts, order history, and reorder are handled by [Toast Online Ordering](https://support.toasttab.com/en/article/Getting-Started-Online-Ordering). This app is a branded shell with Order, Location, FAQ, and Account tabs.

**Pickup only** — the app never offers delivery. Disable delivery in Toast Web as well.

## Requirements

- macOS with Xcode 16+ (tested against Xcode 26)
- iOS 17+ deployment target
- An active Toast Online Ordering public URL for your restaurant

## Open the project

```bash
open HamptonsBurgers.xcodeproj
```

Select a simulator or device, then Run.

Set your **Signing Team** under the HamptonsBurgers target if you run on a physical device.

## Customize branding

| What | Where |
|------|--------|
| App name, colors, Toast URLs, support contact | [`HamptonsBurgers/Config/BrandConfig.swift`](HamptonsBurgers/Config/BrandConfig.swift) |
| Address, hours, map pin | [`HamptonsBurgers/Resources/Content/location.json`](HamptonsBurgers/Resources/Content/location.json) |
| FAQ copy | [`HamptonsBurgers/Resources/Content/faq.json`](HamptonsBurgers/Resources/Content/faq.json) |
| Logo | Replace `Logo.png` in [`HamptonsBurgers/Resources/Assets.xcassets/Logo.imageset`](HamptonsBurgers/Resources/Assets.xcassets/Logo.imageset) |
| App icon | Add a 1024×1024 image in [`HamptonsBurgers/Resources/Assets.xcassets/AppIcon.appiconset`](HamptonsBurgers/Resources/Assets.xcassets/AppIcon.appiconset) |

Colors are hex strings without `#` (for example `C4A35A`). Screens read colors through `Theme`, so you should not hardcode brand colors in feature views.

### Toast URLs

1. In Toast Web go to **Takeout & delivery → Restaurant info**.
2. Copy the public Online Ordering link (`https://www.toasttab.com/...`).
3. Paste it into `BrandConfig.toastOrderingURL`.
4. Optionally set `BrandConfig.toastAccountURL` if you have a dedicated guest/account link; otherwise Account opens the same ordering URL (guests sign in inside Toast).

## Toast Web checklist (pickup)

1. Confirm Online Ordering is enabled for the location.
2. Keep **pickup** dining options on; turn **delivery** off (or do not offer it on the ordering page).
3. Make menus visible for Online Ordering.
4. Assign an auto-fire POS device for kitchen tickets.
5. Place a test pickup order from the app and confirm it appears in Toast.
6. Sign in as a Toast guest and confirm past orders / reorder work.

## How ordering works

Tapping **Order Pickup** (or **Open Toast Account**) presents Toast in `SFSafariViewController`. Toast owns menu, cart, tips, payment (including Apple Pay when Toast supports it), guest login, history, and reorder. No custom Toast Orders API or card handling runs in this app.

## Project layout

```
HamptonsBurgers/
  App/                 # App entry + TabView
  Config/              # BrandConfig + ContentConfig
  Design/              # Theme / Color helpers
  Features/
    Order/             # Order CTA + Safari bridge
    Location/          # Map, hours, call
    FAQ/
    Account/           # Toast guest / history entry
  Resources/
    Assets.xcassets/   # Logo + AppIcon
    Content/           # location.json, faq.json
```

## Out of scope (v1)

- Custom Toast partner Orders / Credit Cards API
- Delivery
- Push notifications
- Android
