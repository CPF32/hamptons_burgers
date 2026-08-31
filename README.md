# Hamptons Burgers

Native SwiftUI iOS app for **Hamptons Burgers**. Ordering, payment, guest accounts, order history, and reorder are handled by [Toast Online Ordering](https://support.toasttab.com/en/article/Getting-Started-Online-Ordering). This app is a branded shell with Order, Visit, FAQ, and Account tabs.

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
| App name, colors, Toast URLs, support contact | `BrandConfig.swift` (gitignored; start from [`BrandConfig.swift.example`](HamptonsBurgers/Config/BrandConfig.swift.example)) |
| Address, hours, map pin | [`HamptonsBurgers/Resources/Content/location.json`](HamptonsBurgers/Resources/Content/location.json) |
| FAQ copy | [`HamptonsBurgers/Resources/Content/faq.json`](HamptonsBurgers/Resources/Content/faq.json) |
| Logo | Replace `Logo.png` in [`HamptonsBurgers/Resources/Assets.xcassets/Logo.imageset`](HamptonsBurgers/Resources/Assets.xcassets/Logo.imageset) |
| App icon | Add a 1024×1024 image in [`HamptonsBurgers/Resources/Assets.xcassets/AppIcon.appiconset`](HamptonsBurgers/Resources/Assets.xcassets/AppIcon.appiconset) |

Colors are hex strings without `#` (for example `C4A35A`). Screens read colors through `Theme`, so you should not hardcode brand colors in feature views.

### Toast URLs

1. In Toast Web go to **Takeout & delivery → Restaurant info**.
2. Copy the public Online Ordering link (`https://www.toasttab.com/...`).
3. Paste it into `BrandConfig.toastOrderingURL`.
4. **Account → Sign In / Create Account** opens Toast’s guest auth on that ordering page (or set `toastSignInURL` / `toastSignUpURL` if you have dedicated links). Guests use Toast’s Create Account / Sign in controls — this app does not store passwords.

## Toast Web checklist (pickup)

1. Confirm Online Ordering is enabled for the location.
2. Keep **pickup** dining options on; turn **delivery** off (or do not offer it on the ordering page).
3. Make menus visible for Online Ordering.
4. Assign an auto-fire POS device for kitchen tickets.
5. Place a test pickup order from the app and confirm it appears in Toast.
6. Sign in as a Toast guest and confirm past orders / reorder work.

## How ordering works

Tapping **Order Pickup**, **Sign In**, or **Create Account** presents Toast in `SFSafariViewController`. Toast owns menu, cart, tips, payment (including Apple Pay when Toast supports it), guest login/sign-up, history, and reorder. No custom Toast Orders API or card handling runs in this app.

## Live store status (admin)

The app supports real-time **patty count**, **sold-out / off-day flags**, and **customer notices** that sync across all guest devices.

### Guest experience

- **Order** tab shows a patty “fuel gauge” (approximate inventory left for the week)
- Admin **notices** appear at the top of the app (events, hour changes, etc.)
- **Order Pickup** is disabled when:
  - Outside regular hours (`location.json`)
  - Admin marks an **off day**
  - Patty count is **0** or admin marks **sold out**
- Tapping the disabled button shows the admin’s custom closed message (or a sensible default)

### Hidden admin screen

1. Open the **Order** tab
2. Tap the **logo 5 times** quickly
3. Enter the admin PIN (`BrandConfig.adminPIN`, default `0824`)
4. Manage flags, patty count, notices, and the order-disabled message
5. Tap **Publish** to push updates to guests

### Firebase Dev + Prod environments

The app supports two Firebase projects:

| Xcode build | App home-screen name | Firebase project | Config file |
|-------------|----------------------|------------------|-------------|
| **Debug** (Run in Xcode) | HB Dev | `hamptons-burgers-dev` | `Firebase/GoogleService-Info-Dev.plist` |
| **Release** (Archive / TestFlight) | Hamptons Burgers | `hamptons-burgers` | `Firebase/GoogleService-Info-Prod.plist` |

Dev and Prod are **separate databases**, so you can test admin changes, rewards, and FAQ edits without touching live guest data.

#### One-time console setup

1. Keep your existing project **`hamptons-burgers`** as Production.
2. In [Firebase Console](https://console.firebase.google.com) create a second project: **`hamptons-burgers-dev`**.
3. In **both** projects:
   - Add an iOS app with bundle ID `com.hamptonsburgers.app`
   - Enable **Cloud Firestore**
   - Download each project’s `GoogleService-Info.plist`
4. Save the downloads as:
   ```bash
   cp ~/Downloads/GoogleService-Info.plist Firebase/GoogleService-Info-Dev.plist   # from hamptons-burgers-dev
   cp ~/Downloads/GoogleService-Info.plist Firebase/GoogleService-Info-Prod.plist  # from hamptons-burgers
   ```
   (Examples live at `Firebase/*.plist.example`.)
5. Deploy security rules to **both** projects:
   ```bash
   firebase login
   firebase use dev && firebase deploy --only firestore:rules
   firebase use prod && firebase deploy --only firestore:rules
   ```
6. Copy brand config if needed, then set the write secret to match [`firestore.rules`](firestore.rules):
   ```bash
   cp HamptonsBurgers/Config/BrandConfig.swift.example HamptonsBurgers/Config/BrandConfig.swift
   ```
   Edit `BrandConfig.firestoreAdminWriteSecret` (that file is gitignored).

#### Daily workflow

- **Test changes:** Run the default scheme in Xcode (**Debug** → Dev Firebase). Home screen says **HB Dev**.
- **Ship live data:** Product → Archive (**Release** → Prod Firebase), or temporarily set the scheme’s Run action to Release.

The hidden admin panel shows the active **Environment** and **Project** ID so you can confirm which backend you’re on.

| Admin setting | Where |
|---------------|--------|
| Admin PIN, Firestore paths, write secret | `BrandConfig.swift` (local; copy from [`BrandConfig.swift.example`](HamptonsBurgers/Config/BrandConfig.swift.example)) |
| Firestore security rules | [`firestore.rules`](firestore.rules) |
| Firebase project aliases | [`.firebaserc`](.firebaserc) |

## Project layout

```
HamptonsBurgers/
  App/                 # App entry + TabView
  Config/              # BrandConfig + ContentConfig
  Design/              # Theme / Color helpers
  Features/
    Order/             # Order CTA + patty gauge + Safari bridge
    Admin/             # Hidden admin PIN + store / content controls
    Location/          # Map, hours, contact (Find Us tab)
    FAQ/
    Account/           # Guest profile (rewards PII)
    Payment/           # Rewards + in-store redemption
  Resources/
    Assets.xcassets/   # Logo + AppIcon
    Content/           # Bundled location/faq/redemption defaults
Firebase/              # GoogleService-Info-Dev/Prod.plist (gitignored)
Scripts/               # CopyFirebaseConfig.sh (Debug→Dev, Release→Prod)
```

## Out of scope (v1)

- Custom Toast partner Orders / Credit Cards API
- Delivery
- Push notifications
- Android
