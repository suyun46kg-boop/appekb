# Google Play submission guide — EKBKG

Package: `mycompany.ekbkyrgyzdar`  
Display name: `EKBKG`  
Current target version (after readiness bump): see `pubspec.yaml`.

This guide prepares Play Console fields. It does **not** upload the AAB.

## 1. Signing (local, required before AAB)

1. Copy template:
   ```powershell
   Copy-Item android\key.properties.example android\key.properties
   ```
2. Edit `android/key.properties` with real `storePassword`, `keyPassword`, and `keyAlias` for `android/app/upload-keystore.jks`.
3. Confirm readiness:
   ```powershell
   powershell -File tool\check_play_readiness.ps1
   ```
4. When ready to build (separate step):
   ```powershell
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`

`android/key.properties` is gitignored. Never commit passwords.

## 2. Version

| Field | Source |
|---|---|
| versionName | `pubspec.yaml` before `+` |
| versionCode | `pubspec.yaml` after `+` |

History jumped from `1.0.1+5` → `1.0.2+8`, which often means intermediate codes were used for store uploads. Readiness check bumped to **`1.0.3+9`** so a new upload is unlikely to collide with an existing Play versionCode.

Before each later upload, increment the `+N` number.

Also keep Supabase `app_config.min_version` ≤ this release so force-update does not block reviewers.

## 3. Play Console — Data safety (answers)

Aligned with in-app privacy copy and [app_store_submission_guide.md](app_store_submission_guide.md).

### Does the app collect / share data?
**Yes** (for app functionality). No sale of data. No cross-app advertising tracking.

### Data types

| Type | Collected | Purpose | Linked to user | Sold |
|---|---|---|---|---|
| Phone number | Yes | Account / seller contact | Yes | No |
| Name | Yes | Profile | Yes | No |
| Photos | Yes | Listing images (camera / gallery) | Yes | No |
| User-generated content | Yes | Listings, reports | Yes | No |
| Device / push IDs (FCM token) | Yes | Push delivery | May be linked | No |
| Approximate location from GPS | **No** | — | — | — |
| Advertising ID | **No** (declare “No” / not used for ads) | — | — | — |

### Security practices
- Data encrypted in transit: **Yes** (HTTPS / Supabase / FCM).
- Users can request deletion: **Yes** — Profile → account deletion (`delete_own_account`), also support within 30 days (see in-app privacy text).

### Third parties
- **Supabase** — auth, listings, profile storage.
- **Firebase Cloud Messaging** — push token / delivery only.

## 4. Play Console — App content checklist

- [ ] **Privacy policy URL** — public HTTPS page (in-app PDF alone is not enough for the listing). Host `docs/privacy_policy.pdf` or an equivalent web page.
- [ ] **Content rating** questionnaire (IARC).
- [ ] **Target audience** — not primarily children (classifieds / adult users).
- [ ] **Photos & videos** permission declaration — used to create listings.
- [ ] **Notifications** — optional push; requested in-app.
- [ ] **Account deletion** — already in app; mention the in-app path in Console if asked.
- [ ] **Ads** — declare no ads if you do not show ads.
- [ ] **Screenshots** — phone (required); 7" / 10" tablet optional but recommended.
- [ ] **Short / full description** — store listing copy (RU/KY as needed).
- [ ] **App access** — if login required for review, provide reviewer phone + password (same pattern as App Store guide Section 1).

## 5. Permissions declared in the Android app

From `AndroidManifest.xml`:

- `INTERNET`
- `POST_NOTIFICATIONS`
- `CAMERA`
- `READ_EXTERNAL_STORAGE` (maxSdk 32)
- `READ_MEDIA_IMAGES`

Justify in Console: camera/photos for listing media; notifications for new listings / category alerts.

## 6. Pre-upload code checklist

Run:

```powershell
powershell -File tool\check_play_readiness.ps1
```

Expect:

- [x] `applicationId` matches `google-services.json`
- [x] Firebase Android configured
- [x] `targetSdkVersion` 36
- [x] Launcher icon + label `EKBKG`
- [x] FCM channel / notification icon
- [x] In-app privacy PDF + account deletion
- [ ] Local `android/key.properties` with real passwords (**blocker until filled**)
- [ ] Play Console fields above completed

## 7. After upload

1. Internal testing track first (recommended).
2. Smoke-test: login, create listing with photo, favorites, notification permission, account deletion entry point.
3. Promote to Production when Internal looks good.
