# Health platform setup notes (Phase 4)

Phase 4 ships write-only sync to Apple Health (iOS) and Android Health Connect.
The Dart side, manifest entries, Info.plist usage descriptions, and a
`Runner.entitlements` file are committed, but two platform tweaks still need
to be done by hand inside Xcode and (optionally) on an Android emulator before
real-device smoke testing:

## iOS

`ios/Runner/Runner.entitlements` exists but is not yet referenced by
`Runner.xcodeproj/project.pbxproj`. To finish wiring it up:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the `Runner` target → `Signing & Capabilities`.
3. Click `+ Capability` and add `HealthKit`.
4. Confirm `Code Signing Entitlements` build setting points to
   `Runner/Runner.entitlements`.
5. Build + run on a real device or simulator with Health permissions enabled.

The `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription`
strings are already in `Info.plist`. Phase 4 only requests WRITE; READ
will be wired in a later phase but is declared in entitlements for forward
compatibility.

## Android

The Health Connect app must be installed on the emulator/device for the
permission prompt to work. On API 34+ it ships with the OS; on older API
levels install it from the Play Store
(`com.google.android.apps.healthdata`).

Permissions and the privacy-policy intent filter are already wired in
`android/app/src/main/AndroidManifest.xml`.

## Smoke checklist

- [ ] Toggle the "Apple Health" / "Health Connect" switch in Settings →
      system permission sheet appears, write-only scope.
- [ ] Save a reading → check it appears in Apple Health (Browse → Heart →
      Blood Pressure) / Health Connect (Browse data → Vitals).
- [ ] Disconnect → `external_sync_records` is cleared, local readings remain.
