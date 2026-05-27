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
form, and the Health Connect declaration. To also surface it on-device (the
"privacy policy" link inside Health Connect), add a guarded `activity-alias` to
the manifest when you do the release work:

```xml
<activity-alias
    android:name="ViewPermissionUsageActivity"
    android:exported="true"
    android:targetActivity=".MainActivity"
    android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
    <intent-filter>
        <action android:name="android.intent.action.VIEW_PERMISSION_USAGE" />
        <category android:name="android.intent.category.HEALTH_PERMISSIONS" />
    </intent-filter>
</activity-alias>
```

This is **not** wired up yet (privacy policy is parked for local testing).

## 1. Permissions used (must match the manifest exactly)

PulseSnap is **write-only by design** — it feeds Health Connect and never reads
back. The app declares only these in `AndroidManifest.xml`:

| Permission | Health Connect data type |
|-----------|--------------------------|
| `android.permission.health.WRITE_BLOOD_PRESSURE` | Blood pressure (write) |
| `android.permission.health.WRITE_HEART_RATE`     | Heart rate (write)     |

> No `READ_*` health permissions are declared, so there is nothing to justify on
> that front — Google's review is simpler for write-only apps. If import is ever
> added later, the corresponding `READ_*` permissions and a justification would
> need to be added back here.

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
   - Select access type: **Write** only (PulseSnap does not read).
   - Paste the privacy policy URL.
   - Provide the **core use case**: "Users record blood pressure and pulse in
     PulseSnap; the app writes confirmed readings to Health Connect so they are
     available to other health apps the user trusts."
   - **Video demonstration:** Google requires a short (≤ ~2 min) unlisted YouTube
     video showing: opening the app → toggling Health Connect ON in Settings →
     granting permission → saving a reading → the reading appearing in Health
     Connect. (This is exactly the on-device activation test — screen-record that
     run.)
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
