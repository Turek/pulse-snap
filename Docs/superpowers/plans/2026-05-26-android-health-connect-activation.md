# Android Health Connect Sync — Activation & Release Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Activate and verify the existing write-only Health Connect sync on Android (so PulseSnap readings appear in Health Connect, and from there in Google Fit / any authorized app), and prepare the manifest + Play Console configuration required to ship it.

**Architecture:** The sync is *already implemented* in `lib/data/health_platform/health_plus_service.dart` (write-only, Phase 4), triggered fire-and-forget from `ReadingRepository.saveReading/updateReading`, toggled by the Settings tile. This plan does **not** rebuild that. It (1) establishes a green baseline, (2) fills two real release gaps — the Health Connect rationale `activity-alias` for Android ≤13 and a privacy-policy URL, (3) verifies activation on a real Android 14+ device, and (4) documents the Google Play Console Health Connect declaration.

**Tech Stack:** Flutter 3.44.0, `health: ^13.3.1` (Health Connect on Android, HealthKit on iOS), `permission_handler: ^11.3.0`, Drift DB. minSdk 26, applicationId `com.pulsesnap.app`.

---

## Critical context (read first)

- **There is no Google Fit API integration, and there must not be.** Google's Fitness/Fit APIs are deprecated and shut down in 2026. The `health` package writes to **Health Connect** on Android. Once data is in Health Connect, Google Fit (or any app the user authorizes) reads it from there. So "sync to Google Fit" = "write to Health Connect."
- The iOS counterpart is **Apple Health / HealthKit** — already implemented, out of scope for this plan.
- The write path is complete and unit/widget tested. The work below is **verification + release config**, not feature development.

## File structure

| File | Responsibility | Action |
|------|----------------|--------|
| `android/app/src/main/AndroidManifest.xml` | Health permissions + Health Connect rationale/privacy intents | Modify — add `activity-alias` + privacy-policy intent for Android ≤13 |
| `lib/data/health_platform/health_plus_service.dart` | Write-only sync service | **No change** — verify only |
| `lib/data/repositories/reading_repository.dart` | Triggers sync on save | **No change** — verify only |
| `lib/features/settings/health_platform_provider.dart` | Toggle/connect/disconnect state | **No change** — verify only |
| `docs/health-connect-play-console.md` | Play Console declaration runbook | Create |
| `test/data/health_platform/health_plus_service_test.dart` | Existing service tests | Run as gate |

---

### Task 1: Establish a green baseline

**Files:**
- Test: `test/data/health_platform/health_plus_service_test.dart`
- Test: `test/data/health_platform/health_platform_tile_test.dart`
- Test: `test/data/reading_repository_sync_test.dart`

- [ ] **Step 1: Fetch dependencies**

Run: `flutter pub get`
Expected: `Got dependencies!` with no version-solve errors.

- [ ] **Step 2: Run the full health-sync test suite to confirm it currently passes**

Run: `flutter test test/data/health_platform/ test/data/reading_repository_sync_test.dart`
Expected: `All tests passed!` — these cover write logic, null-value handling, permission-denied skip, and the settings toggle. If any fail, STOP and fix before touching anything else (use superpowers:systematic-debugging).

- [ ] **Step 3: Static analysis baseline**

Run: `flutter analyze lib/data/health_platform lib/features/settings`
Expected: `No issues found!`

- [ ] **Step 4: Commit the plan (no code change yet)**

```bash
git add docs/superpowers/plans/2026-05-26-android-health-connect-activation.md
git commit -m "docs: add Android Health Connect activation plan"
```

---

### Task 2: Add the Health Connect privacy-policy intent (Android 14+)

**Why:** Your current manifest puts `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE` on `MainActivity` — correct for **Android 14+** (Health Connect is part of the OS). Google Play additionally requires a privacy-policy intent (`VIEW_PERMISSION_USAGE` + `HEALTH_PERMISSIONS` category) so the permissions screen can link to your policy. We are **deliberately skipping** the Android ≤13 `activity-alias` compatibility shim — modern-Android only. `minSdk` stays at 26 (sync still functions on older devices; only the rationale screen is unwired there). This is config-only; verification is the build + the on-device check in Task 3.

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml:36-38` (the existing rationale intent-filter inside `MainActivity`)

- [ ] **Step 1: Add the privacy-policy intent-filter to MainActivity**

In `android/app/src/main/AndroidManifest.xml`, replace the existing single rationale intent-filter block inside the `<activity android:name=".MainActivity">` element:

```xml
            <intent-filter>
                <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE"/>
            </intent-filter>
```

with this (adds the Android-14+ privacy-policy action alongside the rationale):

```xml
            <!-- Health Connect on Android 14+ (OS-integrated): rationale + privacy policy -->
            <intent-filter>
                <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE"/>
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW_PERMISSION_USAGE"/>
                <category android:name="android.intent.category.HEALTH_PERMISSIONS"/>
            </intent-filter>
```

- [ ] **Step 2: Verify the manifest parses by assembling the debug APK**

Run: `flutter build apk --debug`
Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`. A manifest-merge error here means a typo in the XML — fix and re-run. (No unit test covers raw manifest XML; the build is the gate.)

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat(android): Health Connect rationale alias + privacy-policy intent for Android <=13"
```

---

### Task 3: Activate and verify on a real Android 14+ device

**Why:** Health Connect cannot be exercised on a stock emulator without the Health Connect app, and the write path is fire-and-forget — only an on-device check confirms data actually lands. This task is **manual verification**, not automated; record the observed result in each step.

**Files:** none (runtime verification).

**Preconditions:**
- A physical Android 14+ device (Health Connect built in: open Settings → Security & privacy → More privacy settings → Health Connect to confirm it exists).
- Device connected: `flutter devices` lists it.

- [ ] **Step 1: Install and launch the app on the device**

Run: `flutter run --release -d <device-id>`
Expected: App launches on the device. (Release mode avoids debug-permission quirks; `<device-id>` is from `flutter devices`.)

- [ ] **Step 2: Toggle sync on in Settings and grant permissions**

Manual:
1. Open **Settings** tab → find the **Health Connect** integration tile.
2. Toggle it **ON**.
3. The Health Connect permission sheet appears listing *Blood pressure* and *Heart rate* (write). Tap **Allow**.
Expected: Tile subtitle changes from `Not connected` to `Connected`. If you instead see a "permission denied" snackbar, re-toggle and ensure you tap Allow.

- [ ] **Step 3: Save a reading and confirm it syncs**

Manual:
1. Tap the **New Reading** FAB, enter e.g. Systolic 128 / Diastolic 82 / Pulse 70, save.
2. Return to **Settings** → Health Connect tile.
Expected: Subtitle now reads `Connected — last sync <today's date/time>`. (The provider's `refreshLastSync()` reads the newest `ExternalSyncRecords` row.)

- [ ] **Step 4: Confirm the data is actually in Health Connect**

Manual:
1. Open the device **Health Connect** screen → **Data and access** → **Vitals** → **Blood pressure**.
Expected: An entry **128/82 mmHg** attributed to **PulseSnap** at the time you saved. Repeat for **Heart rate** → **70 bpm**. This is the definitive proof that "sync to Google Fit" works — Google Fit, if installed and granted read access, will now show the same entry.

- [ ] **Step 5: Confirm disconnect revokes cleanly**

Manual:
1. In the Settings tile, tap **Disconnect**.
Expected: Subtitle returns to `Not connected`; in Health Connect → **App permissions**, PulseSnap shows no granted permissions. (Disconnect calls `revokePermissions()` on Android and deletes local `ExternalSyncRecords`.)

- [ ] **Step 6: Record results**

No commit. Note pass/fail of Steps 2–5 in the PR description or task notes. If any step fails, debug with superpowers:systematic-debugging before proceeding to Task 4.

---

### Task 4: Document the Google Play Console Health Connect declaration

**Why:** Apps that access Health Connect data **cannot be published** on Google Play without an approved Health Connect declaration and a privacy policy. You don't have a privacy policy yet, and this is a hard gate for release. This task produces a runbook so the release isn't blocked at submission time. (Documentation task — verification is that the file exists and is complete.)

**Files:**
- Create: `docs/health-connect-play-console.md`

- [ ] **Step 1: Create the Play Console runbook**

Create `docs/health-connect-play-console.md` with this exact content:

````markdown
# Publishing PulseSnap with Health Connect — Play Console Runbook

PulseSnap writes Blood Pressure and Heart Rate to **Health Connect** on Android
(via the `health` package). Google Play treats Health Connect data as sensitive
health data, so the listing requires an approved declaration **before** the app
can go to production. Budget 1–2 review cycles.

## 0. Prerequisite: a public privacy policy (BLOCKING)

You do not yet have one. Health Connect and the Play Console both require a
publicly reachable HTTPS URL. The policy must explicitly state:

- That the app accesses **Blood pressure** and **Heart rate** via Health Connect.
- That PulseSnap **writes** these to Health Connect (does not currently read).
- That data is stored locally on device and is not sold or shared with third
  parties for advertising.
- A contact email for data questions.

Host it anywhere stable (GitHub Pages, your domain, a Notion public page). Save
the final URL — it is entered in three places: the Play listing, the Data Safety
form, and the Health Connect declaration. (It is also surfaced on-device via the
`VIEW_PERMISSION_USAGE` intent added to the manifest in Task 2.)

## 1. Permissions used (must match the manifest exactly)

The app declares these in `AndroidManifest.xml`:

| Permission | Health Connect data type |
|-----------|--------------------------|
| `android.permission.health.WRITE_BLOOD_PRESSURE` | Blood pressure (write) |
| `android.permission.health.READ_BLOOD_PRESSURE`  | Blood pressure (read)  |
| `android.permission.health.WRITE_HEART_RATE`     | Heart rate (write)     |
| `android.permission.health.READ_HEART_RATE`      | Heart rate (read)      |

> Note: the app currently only **writes** (Phase 4). The READ permissions are
> declared but unused until import sync (Phase 5) ships. Google asks you to
> justify each permission — if you want to avoid justifying unused READ
> permissions now, you may remove the two `READ_*` lines from the manifest until
> Phase 5. Otherwise, justify them as "reading user's existing readings for
> de-duplication (upcoming feature)."

## 2. Play Console steps

1. **Play Console → your app → Policy → App content.**
2. Open **Privacy policy** → paste the HTTPS URL from step 0 → Save.
3. Open **Data safety** form:
   - Data types collected: **Health and fitness → Health info** (Blood pressure,
     Heart rate).
   - Collected & **not** shared. Stored on device. Mark as not used for
     advertising. Encrypted in transit: N/A (on-device only) — answer per your
     actual data flow.
4. Open **Health Connect** declaration (under *App content*, appears once the
   APK/AAB with `android.permission.health.*` is uploaded to a track):
   - Confirm the data types: Blood pressure, Heart rate.
   - Select access type: **Write** (and Read if you kept the READ permissions).
   - Paste the privacy policy URL.
   - Provide the **core use case**: "Users record blood pressure and pulse in
     PulseSnap; the app writes confirmed readings to Health Connect so they are
     available to other health apps the user trusts."
   - **Video demonstration:** Google requires a short (≤ ~2 min) unlisted YouTube
     video showing: opening the app → toggling Health Connect ON in Settings →
     granting permission → saving a reading → the reading appearing in Health
     Connect. (This is exactly Task 3, Steps 2–4 — screen-record that run.)
5. Submit. Health Connect declarations are reviewed by Google; expect a few days
   and possibly a follow-up request for clarification.

## 3. What you do NOT need

- **No Google Cloud project, OAuth client, or API key.** Health Connect is an
  on-device data store — there is no server-side API to enable. (This is the key
  difference from the deprecated Google Fit REST API.)
- **No Google Fit SDK.** Deprecated; Health Connect replaces it.

## 4. Build for upload

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

Upload the `.aab` to an Internal testing track first so the Health Connect
declaration option unlocks, complete the declaration, then promote to production.
````

- [ ] **Step 2: Verify the file is complete (no placeholders)**

Run: `grep -nE "TODO|TBD|FIXME|XXX" docs/health-connect-play-console.md`
Expected: no output (exit code 1 / nothing printed).

- [ ] **Step 3: Commit**

```bash
git add docs/health-connect-play-console.md
git commit -m "docs: Play Console Health Connect declaration runbook"
```

---

## Self-review

**Spec coverage** (against the user's request):
- "Review codebase / find the integration" → done in pre-plan investigation; Critical context section documents it's Health Connect, not Google Fit.
- "Activate Android sync, want data synced there" → Task 3 (on-device activation + proof data lands in Health Connect).
- "Some code is there but not sure all" → Task 1 confirms the existing write path is green; Task 2 adds the privacy-policy intent (Android ≤13 compat shim deliberately skipped per decision).
- "Details for Google Play Store config" → Task 4 (full runbook incl. declaration, data safety, video demo, privacy policy, and the explicit "no Cloud project needed" clarification).

**Placeholder scan:** Task 4 Step 2 actively greps for placeholders; manifest XML in Task 2 is complete literal blocks; commands are concrete.

**Consistency:** `applicationId com.pulsesnap.app`, `minSdk 26`, permission names, and `ACTION_SHOW_PERMISSIONS_RATIONALE` match the actual manifest read during investigation. The `activity-alias` `targetActivity=".MainActivity"` matches the real activity name.

**Known open decision (flagged, not blocking):** the manifest declares unused `READ_*` health permissions (Phase 5 not shipped). Task 4 §1 notes the choice — justify them or remove until import lands. Decide before submitting to Google.
