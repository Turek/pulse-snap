# PulseSnap — Product Addendum Specification

## Scope

This addendum extends the original PulseSnap MVP specification with four product areas in the following priority order:

1. Health indicator thresholds with Flutter enums and color tokens.
2. Tags replacing free-form notes, while preserving a custom quick-input tag option.
3. Doctor-facing PDF export without personal name fields.
4. Health platform integrations for Apple Health and Android Health Connect.

This addendum is intended to be implementation-ready for a Flutter development team and aligned with commonly cited public guidance from the American Heart Association, NHS, CDC, and Android/Apple health platform documentation.[cite:197][cite:217][cite:212][cite:196]

## Health indicators

### Product rules

The app should classify blood pressure and pulse separately, then derive an overall reading severity from the more severe of the two. Blood pressure thresholds should follow the American Heart Association categories for high blood pressure and the NHS threshold for low blood pressure.[cite:197][cite:217] Resting pulse thresholds should use the American Heart Association normal adult resting range of 60 to 100 bpm, while treating lower values carefully because athletic users may have lower resting rates.[cite:200][cite:207][cite:208]

The UI should not present these categories as diagnoses. It should present them as status indicators and trend signals, with stronger warning language only for clearly elevated or urgent thresholds such as blood pressure above 180 systolic or above 120 diastolic.[cite:197]

### Threshold tables

#### Blood pressure status

| Status | Systolic | Diastolic | UI meaning | Color token | Source |
|---|---:|---:|---|---|---|
| Low | `< 90` | or `< 60` | Below typical range; highlight especially if symptomatic | `bpLow` | [cite:217] |
| Normal | `< 120` | and `< 80` | In normal range | `bpNormal` | [cite:197] |
| Elevated | `120–129` | and `< 80` | Above normal, not yet hypertension | `bpElevated` | [cite:197] |
| High Stage 1 | `130–139` | or `80–89` | High blood pressure | `bpHigh1` | [cite:197] |
| High Stage 2 | `>= 140` | or `>= 90` | Very high blood pressure | `bpHigh2` | [cite:197] |
| Crisis | `> 180` | or `> 120` | Urgent review / emergency messaging tier | `bpCrisis` | [cite:197] |

#### Resting heart rate status

| Status | BPM | UI meaning | Color token | Source |
|---|---:|---|---|---|
| Very Low | `< 50` | Low resting pulse; may be normal for trained users, but still highlight | `hrVeryLow` | [cite:207][cite:200] |
| Low | `50–59` | Slightly low / borderline low | `hrLow` | [cite:207][cite:200] |
| Normal | `60–100` | Normal adult resting range | `hrNormal` | [cite:200] |
| Mildly High | `101–110` | Slightly elevated resting pulse | `hrHigh1` | [cite:208][cite:200] |
| High | `111–130` | Clearly elevated resting pulse | `hrHigh2` | [cite:208] |
| Very High | `> 130` | Strong alert tier for resting reading | `hrHigh3` | [cite:208] |

### Classification logic

Blood pressure classification must use the highest-severity side of the reading, not an average. For example, `128/92` must classify as `High Stage 2`, because the diastolic value is already in that category.[cite:197] Pulse classification should be used as a resting indicator only; when the reading is tagged with exercise or similar context, the UI should de-emphasize high-pulse warnings and show a contextual label instead of an alarming interpretation.[cite:200]

### Flutter enums

```dart
enum BloodPressureStatus {
  low,
  normal,
  elevated,
  highStage1,
  highStage2,
  crisis,
}

enum HeartRateStatus {
  veryLow,
  low,
  normal,
  mildlyHigh,
  high,
  veryHigh,
}

enum SeverityLevel {
  info,
  normal,
  caution,
  warning,
  danger,
  urgent,
}
```

### Flutter classification helpers

```dart
BloodPressureStatus classifyBloodPressure({
  required int systolic,
  required int diastolic,
}) {
  if (systolic > 180 || diastolic > 120) {
    return BloodPressureStatus.crisis;
  }
  if (systolic >= 140 || diastolic >= 90) {
    return BloodPressureStatus.highStage2;
  }
  if ((systolic >= 130 && systolic <= 139) ||
      (diastolic >= 80 && diastolic <= 89)) {
    return BloodPressureStatus.highStage1;
  }
  if (systolic >= 120 && systolic <= 129 && diastolic < 80) {
    return BloodPressureStatus.elevated;
  }
  if (systolic < 90 || diastolic < 60) {
    return BloodPressureStatus.low;
  }
  return BloodPressureStatus.normal;
}

HeartRateStatus classifyHeartRate({
  required int bpm,
}) {
  if (bpm > 130) return HeartRateStatus.veryHigh;
  if (bpm >= 111) return HeartRateStatus.high;
  if (bpm >= 101) return HeartRateStatus.mildlyHigh;
  if (bpm >= 60) return HeartRateStatus.normal;
  if (bpm >= 50) return HeartRateStatus.low;
  return HeartRateStatus.veryLow;
}

SeverityLevel severityFromBloodPressure(BloodPressureStatus status) {
  switch (status) {
    case BloodPressureStatus.low:
      return SeverityLevel.info;
    case BloodPressureStatus.normal:
      return SeverityLevel.normal;
    case BloodPressureStatus.elevated:
      return SeverityLevel.caution;
    case BloodPressureStatus.highStage1:
      return SeverityLevel.warning;
    case BloodPressureStatus.highStage2:
      return SeverityLevel.danger;
    case BloodPressureStatus.crisis:
      return SeverityLevel.urgent;
  }
}

SeverityLevel severityFromHeartRate(HeartRateStatus status) {
  switch (status) {
    case HeartRateStatus.veryLow:
      return SeverityLevel.info;
    case HeartRateStatus.low:
      return SeverityLevel.caution;
    case HeartRateStatus.normal:
      return SeverityLevel.normal;
    case HeartRateStatus.mildlyHigh:
      return SeverityLevel.caution;
    case HeartRateStatus.high:
      return SeverityLevel.warning;
    case HeartRateStatus.veryHigh:
      return SeverityLevel.danger;
  }
}
```

### Flutter color tokens

The app should use semantic tokens instead of hardcoded per-screen colors. These colors are product suggestions, not medical standards. The thresholds come from health organisations; the visual design mapping is product-defined.[cite:197][cite:217][cite:200]

```dart
import 'package:flutter/material.dart';

@immutable
class VitalColors {
  static const bpLow = Color(0xFF2F80ED);
  static const bpNormal = Color(0xFF27AE60);
  static const bpElevated = Color(0xFFF2C94C);
  static const bpHigh1 = Color(0xFFF2994A);
  static const bpHigh2 = Color(0xFFEB5757);
  static const bpCrisis = Color(0xFF8B1E3F);

  static const hrVeryLow = Color(0xFF3F8CFF);
  static const hrLow = Color(0xFF56CCF2);
  static const hrNormal = Color(0xFF27AE60);
  static const hrHigh1 = Color(0xFFF2C94C);
  static const hrHigh2 = Color(0xFFF2994A);
  static const hrHigh3 = Color(0xFFEB5757);

  static const infoBg = Color(0xFFEAF3FF);
  static const successBg = Color(0xFFEAF8EF);
  static const cautionBg = Color(0xFFFFF7E0);
  static const warningBg = Color(0xFFFFEFE2);
  static const dangerBg = Color(0xFFFDECEC);
  static const urgentBg = Color(0xFFF8E6EC);
}
```

### UI presentation rules

- Blood pressure status pill is primary in the reading card because it is the core metric for this app.[cite:197]
- Heart rate status appears as a secondary pill beside the pulse value.[cite:200]
- If BP is `crisis`, show a top banner and a non-dismissed warning state on the reading detail screen.[cite:197]
- If heart rate is high but the reading includes the tag `after exercise`, replace the warning subtitle with `Elevated pulse may reflect recent activity`.[cite:200]
- If BP is low, the app should prefer an informative tone unless the user also tags dizziness or faintness-like symptoms; NHS guidance emphasises symptoms in hypotension interpretation.[cite:217]

## Tags instead of notes

### Product change

The free-form notes field is replaced by a structured tags system, because structured context is much more useful for filtering, analytics, export, and doctor review. A custom tag entry remains available through a quick input control so users can still capture uncommon contexts.

### Default tag set

The first release should include these built-in tags as quick chips:

- `before medication`
- `after medication`
- `after coffee`
- `after exercise`
- `stress`
- `headache`
- `dizziness`
- `lying`
- `sitting`
- `standing`
- `custom...`

These tags reflect common contextual variables around home monitoring and symptoms, and they map well to filtering and export workflows.[cite:215][cite:217]

### UX rules

On the Review screen, tags appear below the values and status chips. Users can tap multiple tags. Tapping `custom...` opens a compact inline input field with immediate save into a one-off custom tag. The user should not need to open a separate modal unless the platform keyboard layout forces it.

Example layout:

```text
Tags
[before medication] [after medication] [after coffee]
[after exercise] [stress] [headache]
[dizziness] [lying] [sitting] [standing] [custom...]

Custom tag: [________________] [Add]
```

### Data model

The `notes` column should be removed from the core schema and replaced with `reading_tags`.

```dart
@DataClassName('ReadingTag')
class ReadingTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get readingId => integer()();
  TextColumn get value => text()();
  BoolColumn get isSystemTag => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

### Domain model

```dart
class ReadingWithTags {
  final Reading reading;
  final List<String> tags;

  const ReadingWithTags({
    required this.reading,
    required this.tags,
  });

  bool hasTag(String tag) =>
      tags.any((t) => t.toLowerCase() == tag.toLowerCase());
}
```

### Repository additions

```dart
abstract class IReadingRepository {
  Future<void> saveReading(Reading reading, {List<String> tags = const []});
  Future<void> updateReading(Reading reading, {List<String> tags = const []});
  Future<void> deleteReading(int id);
  Future<ReadingWithTags?> getReadingWithTags(int id);
  Stream<List<ReadingWithTags>> watchAllReadingsWithTags();
  Future<List<ReadingWithTags>> getReadingsByTag(String tag);
  Future<List<String>> getAllUsedTags();
}
```

### Filtering and analytics

Tags should be first-class filters in History, Calendar day detail, and PDF export. The app should support:

- Filter by one tag.
- Filter by multiple tags with `AND` or `ANY` mode.
- Summary counts such as `12 readings after medication` or `8 readings after coffee`.
- Chart overlays by tag in a later phase.

## PDF export

### Product goals

The PDF must be doctor-friendly, structured, and printable, but it must not include the user’s personal name. This matches the requested privacy posture and still allows useful clinical review because the reading timeline, averages, timestamps, and tags are the most important information.[cite:212][cite:218]

### Export types

The app should support three export presets:

1. `Last 7 days`
2. `Last 14 days`
3. `Custom date range`

A fourth option, `Last 30 days`, can be included if charts remain readable at that density.

### PDF structure

#### Page 1: summary

- Title: `PulseSnap Blood Pressure & Pulse Report`
- Date range
- Generated at timestamp
- Data sources included, for example `Scanned`, `Manual`, `Apple Health import`, `Health Connect import`
- Summary cards:
  - Average systolic
  - Average diastolic
  - Average pulse
  - Highest BP
  - Lowest BP
  - Number of readings
- Main trend chart
- Morning vs evening mini-summary

This format reflects the structure commonly seen in home BP logs and gives a clinician a quick overview before the detailed table.[cite:212][cite:218][cite:215]

#### Page 2+: detailed table

| Date/Time | SYS | DIA | Pulse | BP Status | HR Status | Tags | Source |
|---|---:|---:|---:|---|---|---|---|
| 2026-05-19 08:32 | 128 | 82 | 71 | High Stage 1 | Normal | after coffee, sitting | Scanned |

Rules:
- One row per saved reading.
- Tags should be comma-separated and wrap cleanly.
- Long exports should paginate with repeated column headers.
- Cells should use light semantic shading for BP status only if print contrast remains acceptable.
- No personal name, no address, no email.

### PDF chart requirements

Include:

- Main line chart with systolic, diastolic, and pulse.[cite:212]
- Optional reference bands or thin guide lines for BP thresholds at 120, 130, 140, 80, and 90.[cite:197]
- Optional marker color by BP status.

Exclude:

- Heavy decorative graphics.
- Dense annotation per point unless the export is under 14 readings.

### PDF footer text

Use a neutral footer on every page:

`This report contains home-monitored readings recorded in PulseSnap. It is intended to support review and discussion with a clinician and is not a diagnosis.`

This is a product/legal safety guard, not a medical citation.

### Suggested Flutter implementation

Recommended generation stack:

- `pdf` package for document generation.
- `printing` package for preview/share/print.
- Chart rendered to image using a Flutter chart widget capture or custom painter.

Example service interface:

```dart
abstract class IReportExportService {
  Future<Uint8List> buildPdfReport({
    required DateTime from,
    required DateTime to,
    required List<ReadingWithTags> readings,
  });
}
```

### PDF screen flow

`Settings` or `Export` action from Dashboard should open:

1. Range selector
2. Include sources filter
3. Include charts toggle
4. Generate preview
5. Share / Save / Print

The export flow should be available offline for local data and should not depend on server rendering.

## Health platforms

### Product goals

Health-platform sync should come after the core app experience and PDF export. It should be user-controlled, explicit, and source-aware. Apple Health and Android Health Connect are the right targets, not legacy Google Fit APIs, because Health Connect is the current Android health-data layer and Apple Health remains the standard health hub on iOS.[cite:196][cite:199][cite:202][cite:192]

### Sync model

The app should support:

- Write confirmed readings to platform health storage.
- Read existing user-authorised readings into the app as imported records.
- Deduplicate by timestamp, source, and value hash.
- Mark imported entries as read-only unless explicitly copied into local editable form.

### Apple Health

On iOS, the app should integrate with HealthKit for heart rate and blood pressure-related data types. HealthKit exposes heart rate as a quantity type, while blood pressure is represented through systolic and diastolic values linked as a blood pressure correlation.[cite:191][cite:192][cite:193][cite:204]

Recommended scope:

- Write systolic blood pressure.
- Write diastolic blood pressure.
- Write heart rate.
- Read the same fields back if permissions are granted.

Permission principles:

- Request permissions only when the user explicitly enables Apple Health sync.
- Separate read and write permission messaging.
- Make it clear that only confirmed readings are synced.

### Android Health Connect

On Android, the app should integrate with Health Connect, which is Google’s modern health-data platform for Android and provides centralised, user-controlled health-data sharing between apps.[cite:196][cite:199][cite:202] Health Connect supports common health records and is the correct Android target instead of building directly around the older Google Fit model for new product planning.[cite:196][cite:199]

Recommended scope:

- Write blood pressure records.
- Write heart rate records.
- Read existing blood pressure and heart rate records.

Permission principles:

- Request granular permissions only when enabling sync.[cite:199]
- Show last sync time and number of imported/exported records.
- Let users disconnect without deleting local data.

### Data mapping

```dart
enum ReadingSourceType {
  scanned,
  manual,
  appleHealthImport,
  appleHealthExport,
  healthConnectImport,
  healthConnectExport,
}
```

```dart
class ExternalSyncRecord {
  final int readingId;
  final ReadingSourceType sourceType;
  final String externalId;
  final DateTime syncedAt;
  final String platform; // apple_health | health_connect

  const ExternalSyncRecord({
    required this.readingId,
    required this.sourceType,
    required this.externalId,
    required this.syncedAt,
    required this.platform,
  });
}
```

### Settings UI

Add a `Health Platforms` section under Settings:

- `Apple Health` / `Health Connect` connection tile
- Permission status
- Last sync timestamp
- Sync direction toggles:
  - `Write confirmed readings`
  - `Import existing readings`
- Manual `Sync now` button
- Disconnect action

### Rollout order

1. Local app only.
2. PDF export.
3. Apple Health write-only + Health Connect write-only.
4. Bidirectional import.
5. Deduplication and conflict resolution UI.

This order reduces complexity and keeps the first sync release safe and understandable.[cite:196][cite:199][cite:192]

## Addendum impact on existing spec

The following changes should be applied to the original specification:

- Replace `notes` everywhere with `tags` plus `custom tag` input.
- Add threshold classification services as shared domain utilities.
- Add status chips and alert banners to Review, Dashboard, History row, Calendar detail, and Reading Detail screens.
- Add export flow and PDF generation service.
- Add Health Platforms settings section and external sync metadata storage.
- Add read-only treatment for imported records in UI.

## Recommended implementation order

1. Threshold engine, enums, tokens, and status UI. ✅ Shipped 1.0.1
2. Tags model, tag chips, tag filtering, migration away from notes. ✅ Shipped 1.0.2
3. PDF export service and export screens. ✅ Shipped 1.0.3
4. Apple Health and Health Connect write-only sync. ✅ Shipped 1.0.4
5. Import sync and deduplication. ⏳ Deferred to 1.2.x
