# Apple App Store Submission Guide: EKBKG (Version 1.0.1)

This guide contains all necessary credentials, App Store Connect metadata templates, privacy disclosures, iPad testing instructions, and pre-submission checklists required for the App Store review of **EKBKG** (`mycompany.ekbkyrgyzdar`).

---

## 1. Demo Credentials for App Store Reviewers

The app authenticates users using a phone number and password. In the Russian mobile format, the phone number begins with `+7`, which is **statically displayed** in the app UI (`_phoneField()`). The reviewer only needs to enter the remaining 10 digits.

### Credentials

| Parameter | Value | Note |
|---|---|---|
| **App Display Name** | `EKBKG` | Defined in `Info.plist` |
| **Phone Number (UI)** | `9990001122` | Enter in phone input field (the `+7` prefix is static) |
| **Password** | `Review2026!` | At least 8 characters (passes `passlenth`) |
| **Account Type** | Verified Active User | Has active listings for testing |
| **Internal Auth Email** | `9990001122@app.com` | Internal Supabase Auth email representation |
| **Display Name** | `App Reviewer` | Profile name |

### SQL Script to Seed/Verify the Reviewer Account in Supabase

Run the following SQL snippet in the **Supabase SQL Editor** before submitting the build for review:

```sql
-- Create or update demo reviewer user in auth.users
DO $$
DECLARE
  demo_uid uuid := '00000000-0000-0000-0000-000000000099'::uuid;
  demo_email text := '9990001122@app.com';
  demo_pass text := 'Review2026!';
BEGIN
  -- Insert into auth.users if not exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = demo_email) THEN
    INSERT INTO auth.users (
      id,
      instance_id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) VALUES (
      demo_uid,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      demo_email,
      crypt(demo_pass, gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"name":"App Reviewer"}'::jsonb,
      now(),
      now()
    );
  ELSE
    UPDATE auth.users
    SET encrypted_password = crypt(demo_pass, gen_salt('bf')),
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        updated_at = now()
    WHERE email = demo_email;
  END IF;

  -- Ensure matching profile in public."user" or public.users
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user') THEN
    INSERT INTO public."user" (id, nomer, name, created_at)
    VALUES (demo_uid::text, demo_email, 'App Reviewer', now())
    ON CONFLICT (id) DO UPDATE
    SET nomer = EXCLUDED.nomer,
        name = EXCLUDED.name;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    INSERT INTO public.users (id, nomer, name, created_at)
    VALUES (demo_uid::text, demo_email, 'App Reviewer', now())
    ON CONFLICT (id) DO UPDATE
    SET nomer = EXCLUDED.nomer,
        name = EXCLUDED.name;
  END IF;
END $$;
```

---

## 2. "App Review Information" Notes Template for App Store Connect

Copy and paste the template below into the **App Review Information** section in App Store Connect.

### Sign-in Information

- **Sign-in required**: ☑ Checked
- **User name**: `9990001122`
- **Password**: `Review2026!`

### Notes (Copy-Paste for Reviewer Notes)

```text
Dear App Store Review Team,

Thank you for reviewing EKBKG.

1. DEMO ACCOUNT & LOGIN INSTRUCTIONS:
- The app supports both guest browsing and authenticated operations.
- To log in:
  1. Open the app and tap the Profile icon (far right) in the bottom navigation bar.
  2. Tap the "Войти" (Log In) button to open the Authorization screen.
  3. The phone field has a pre-filled "+7" prefix. Enter: 9990001122
  4. Enter the password: Review2026!
  5. Tap "Войти" to sign in.

2. USER-GENERATED CONTENT (UGC) SAFETY (Guideline 1.2):
EKBKG is a local community classifieds marketplace. To ensure user safety:
- In-App Reporting: Every listing detail page has a flag/report button. Tapping it opens a modal allowing any user (authenticated or guest) to report content for spam, fraud, prohibited, or offensive items. Reports with 3 or more flags are automatically placed under review.
- In-App Blocking: Users can block obnoxious sellers directly from the listing page ("Заблокировать продавца") or user profile. Blocked sellers' listings are immediately hidden from the feed.
- Terms of Use (EULA): Users must agree to Terms of Use upon registration. The EULA and Privacy Policy are also accessible anytime via Profile -> "Политика конфиденциальности" (Privacy Policy / Terms). We maintain a strict zero-tolerance policy against objectionable content.

3. IN-APP ACCOUNT DELETION (Guideline 5.1.1(v)):
- To test self-service account deletion:
  1. Sign in with the demo account.
  2. Navigate to Profile.
  3. Scroll to the bottom and tap "Удалить аккаунт" (Delete Account).
  4. Confirm deletion in the alert dialog.
  5. The app immediately invokes the backend delete_own_account RPC, completely deleting the user's auth record, profile data, and associated listings, clears the session, and returns to the guest home page.

4. IPAD SUPPORT:
- The app is a Universal binary supporting both iPhone and iPad in full-screen mode (UIRequiresFullScreen = true).
- Grids and listings adapt dynamically to iPad screen widths.

If you have any questions or require additional information, please contact us immediately.
```

---

## 3. App Privacy Questionnaire Guidance

In App Store Connect, under **App Privacy**:

### A. Location Permission — Removal Confirmation
- **Status in Code**: All location permission keys (`NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`) **have been completely removed** from `ios/Runner/Info.plist`.
- **GPS / Geolocation Tracking**: The application does **NOT** access, track, or collect device GPS coordinates or precise/coarse location.
- **Listing City**: City and district names (e.g., "Екатеринбург") are selectable text tags for categorized browsing, not collected from device sensors.
- **Answer in App Store Connect**: **"No, we do not collect location data from this app."**

### B. Data Types Collected and Usage Declarations

#### 1. Contact Info
- **Phone Number & Name**:
  - **Collected**: Yes.
  - **Usage**: App Functionality (user registration, seller contact).
  - **Linked to user**: Yes (linked to the user's account).
  - **Tracking**: **No**.

#### 2. User Content
- **Photos / Videos**:
  - **Collected**: Yes.
  - **Usage**: App Functionality (allowing users to upload photos for classified listings via camera or photo library).
  - **Permissions declared in Info.plist**:
    - `NSCameraUsageDescription`: *"Camera access is required to take a photo for a listing."*
    - `NSPhotoLibraryUsageDescription`: *"Photo library access is required to select a photo for a listing."*
  - **Linked to user**: Yes (associated with the uploaded listing).
  - **Tracking**: **No**.
- **Customer Support / Reports**:
  - **Collected**: Listing reports submitted by users/guests.
  - **Usage**: App Functionality & Safety moderation.
  - **Linked to user**: Yes (authenticated users) or unlinked (guests).
  - **Tracking**: **No**.

#### 3. Identifiers
- **Device ID / Push Token (APNs / FCM)**:
  - **Collected**: Yes (for push notification delivery).
  - **Usage**: App Functionality.
  - **Linked to user**: May be linked to user ID or unlinked for guest device tokens.
  - **Tracking**: **No**.

#### 4. Tracking Declaration
- **Question**: *"Do you or your third-party partners use data from this app to track users across apps and websites owned by other companies?"*
- **Answer**: **NO**. The app does not participate in cross-app tracking or advertising data brokers.

---

## 4. iPad Review Testing Notes

Apple requires Universal apps submitted to the App Store to function properly on iPad devices without layout distortion or crashes.

### Configuration Highlights
1. **Universal Target**:
   - `TARGETED_DEVICE_FAMILY = "1,2"` is configured in `Runner.xcodeproj` (supports iPhone and iPad).
2. **Full Screen Mode**:
   - `UIRequiresFullScreen` is set to `<true/>` in `ios/Runner/Info.plist`.
   - This prevents window resizing glitches under iPadOS Stage Manager and ensures a stable full-screen presentation.
3. **Orientation Support**:
   - Supported iPad orientations:
     - `UIInterfaceOrientationPortrait`
     - `UIInterfaceOrientationPortraitUpsideDown`
     - `UIInterfaceOrientationLandscapeLeft`
     - `UIInterfaceOrientationLandscapeRight`

### Responsive Layout & Column Verification
- **Category Grid (`DbddWidget`)**:
  - Displays as a balanced 4-column quick navigation bar on both iPhone and iPad.
- **Listings Feed Grid**:
  - Built with sliver grid layouts (`SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)` and responsive product cards).
  - On iPad displays (iPad mini, iPad 11", iPad 13"), cards scale smoothly with proper aspect ratio and spacing.
- **Dialogs & Modals**:
  - Report listing bottom sheets and confirmation dialogs constrain max width to prevent stretching across widescreen iPad canvases.
- **Top / Safe Area Handling**:
  - Utilizes `EkbAppBarBackground` and `MediaQuery.paddingOf(context)` to respect dynamic status bars on iPad.

---

## 5. Final Pre-Submission Checklist

Complete each check before submitting the build for review:

### Step 1: Backend & Database Migration
- [ ] Run `/Users/egor/Projects/appekb/supabase_migrations/20260916_app_store_prep.sql` in the Supabase Dashboard SQL Editor.
- [ ] Verify `delete_own_account()` function exists:
  ```sql
  SELECT proname, prosecdef FROM pg_proc WHERE proname = 'delete_own_account';
  ```
- [ ] Verify `listing_reports` RLS allows anonymous and authenticated inserts:
  ```sql
  SELECT policyname, roles, cmd FROM pg_policies WHERE tablename = 'listing_reports';
  ```
- [ ] Verify `app_config` version guard:
  ```sql
  SELECT min_version, latest_version, ios_url FROM public.app_config WHERE id = 'default';
  ```
  *(Must show `min_version <= '1.0.1'` so the app does not show a blocking force-update modal during review).*
- [ ] Execute reviewer account seeding SQL (from Section 1 above).

### Step 2: iOS Build & Permissions
- [ ] Verify `ios/Runner/Info.plist` has **NO** `NSLocation` keys.
- [ ] Verify `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` are present and clear.
- [ ] Verify `pubspec.yaml` version is `1.0.1+4` (or incremented build number for new submission).
- [ ] Run iOS release build:
  ```bash
  flutter build ipa --release
  ```
- [ ] Validate archive in Xcode Organizer or upload via Transporter / xcrun.

### Step 3: Functional Smoke Test on Device or Simulator
- [ ] **Guest Mode**: Launch app -> Browse feed -> Open listing -> Tap Report -> Submit guest report -> Verify success toast.
- [ ] **Login**: Tap Profile -> Enter `9990001122` and `Review2026!` -> Verify login success.
- [ ] **UGC Blocking**: Open listing -> Tap Block Seller -> Verify confirmation and seller's listings removal.
- [ ] **EULA**: Navigate to Profile -> Tap "Политика конфиденциальности" -> Verify legal terms load.
- [ ] **Account Deletion**: In Profile, tap "Удалить аккаунт" -> Confirm -> Verify immediate logout and return to guest home screen.

### Step 4: App Store Connect Setup
- [ ] Select Build in App Store Connect.
- [ ] Paste Demo Credentials (`9990001122` / `Review2026!`) in **App Review Information**.
- [ ] Paste Notes text from Section 2 above into **Reviewer Notes**.
- [ ] Set App Privacy questionnaire (Section 3 above: No Location, Photos for app functionality, No tracking).
- [ ] Upload required screenshots (6.9" / 6.5" iPhone and 13" iPad Pro).
- [ ] Click **Submit for Review**.

### Step 5: Post-Approval Step
- [ ] Once Apple assigns the public App ID / URL, update `app_config`:
  ```sql
  UPDATE public.app_config
  SET ios_url = 'https://apps.apple.com/app/id<APPLE_APP_ID>',
      updated_at = now()
  WHERE id = 'default';
  ```
