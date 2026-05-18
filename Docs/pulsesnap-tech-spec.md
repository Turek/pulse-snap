# PulseSnap — Technical Specification
**Version:** 1.0 (MVP)  
**Stack:** Flutter 3.x · Material Design 3 · ASP.NET Core (optional backend) · SQLite (local) · Google ML Kit · Gemini Flash (fallback)  
**Date:** May 2026  

---

## 1. Project Overview

PulseSnap is a health data diary app that allows users to photograph any blood pressure or pulse device and automatically extract, store, and visualise their readings. The app requires zero manual data entry — open, snap, confirm, done.

### Design Philosophy
- **Zero friction**: camera is always one tap away
- **Device-agnostic**: no hardcoding per-device layouts
- **Privacy-first**: data stored locally on device by default
- **Extensible**: recognition pipeline is interface-driven and swappable
- **Offline-first**: all core features work without internet

---

## 2. Feature Scope

### MVP (Phase 1)
- [x] Camera capture with guide overlay
- [x] Image preprocessing (sharpen, contrast, grayscale)
- [x] ML Kit single-pass OCR + label proximity matching
- [x] Confidence scoring and manual correction fallback UI
- [x] Local SQLite storage of readings
- [x] Dashboard: latest reading card + 30-day line chart
- [x] History list with filter/search
- [x] Calendar view with reading dot markers
- [x] Reading detail screen with edit/delete
- [x] Light/dark mode (Material 3 dynamic colour)

### Phase 2
- [ ] TFLite object detection pre-pass (crop region → OCR)
- [ ] Gemini Flash API fallback (triggered on low confidence)
- [ ] Multi-user profiles (family members)
- [ ] PDF/CSV export
- [ ] Blood pressure categorisation (Normal / Elevated / Hypertension Stage 1/2)

### Phase 3
- [ ] Apple HealthKit / Google Health Connect sync
- [ ] Doctor-sharing PDF report
- [ ] Self-hosted backend (ASP.NET Core) for multi-device sync
- [ ] Watch companion (Wear OS / watchOS)

---

## 3. Architecture

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
│                                                         │
│  Presentation Layer                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ Camera   │ │Dashboard │ │ History  │ │Calendar  │  │
│  │ Screen   │ │ Screen   │ │ Screen   │ │ Screen   │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│                                                         │
│  Domain Layer (Riverpod providers + use cases)          │
│  ┌──────────────────┐  ┌───────────────────────────┐   │
│  │ ReadingRepository│  │ ScanOrchestrator          │   │
│  └──────────────────┘  └───────────────────────────┘   │
│                                                         │
│  Data Layer                                             │
│  ┌──────────┐  ┌─────────────────────────────────────┐ │
│  │ SQLite   │  │ Recognition Pipeline                │ │
│  │(drift)   │  │ MlKitScanner | TfLiteScanner |      │ │
│  └──────────┘  │ GeminiScanner (all extend IScanner) │ │
│                └─────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
         │ (Phase 3)
         ▼
  ASP.NET Core API  ←→  PostgreSQL
```

### 3.2 State Management
**Riverpod 3.x** — providers for:
- `readingsProvider` — stream of all readings from SQLite
- `scannerProvider` — current active scanner implementation
- `dashboardStatsProvider` — computed stats (avg, min, max per period)
- `calendarReadingsProvider` — readings grouped by date

### 3.3 Navigation
**go_router** with named routes:

```
/                 → DashboardScreen
/scan             → CameraScreen
/scan/review      → ReviewScreen (extracted values + edit)
/history          → HistoryScreen
/history/:id      → ReadingDetailScreen
/calendar         → CalendarScreen
/settings         → SettingsScreen
```

---

## 4. Recognition Pipeline (Core Interface)

This is the most critical architectural decision. All scanner implementations share one interface so any scanner can be swapped or chained without touching UI code.

### 4.1 Interface Definition

```dart
/// Represents extracted vital signs from a single scan.
class ScanResult {
  final int? systolic;      // mmHg, null if not detected
  final int? diastolic;     // mmHg, null if not detected
  final int? pulse;         // bpm
  final double confidence;  // 0.0 – 1.0
  final ScannerType source; // which scanner produced this
  final String? debugInfo;  // optional raw OCR text for logging

  const ScanResult({
    this.systolic,
    this.diastolic,
    this.pulse,
    required this.confidence,
    required this.source,
    this.debugInfo,
  });

  bool get isComplete =>
      systolic != null && diastolic != null && pulse != null;

  bool get isPlausible =>
      (systolic ?? 0) >= 60 && (systolic ?? 999) <= 250 &&
      (diastolic ?? 0) >= 40 && (diastolic ?? 999) <= 150 &&
      (pulse ?? 0) >= 30 && (pulse ?? 999) <= 220;
}

enum ScannerType { mlKit, tflite, geminiFlash, manual }

/// All scanners implement this abstract class.
abstract class IScanner {
  ScannerType get type;

  /// Process a captured image file and return extracted vital signs.
  Future<ScanResult> scan(File imageFile);

  /// Optional: dispose resources (model instances, etc.)
  void dispose() {}
}
```

### 4.2 Scan Orchestrator

Manages which scanner to invoke and when to chain to a fallback:

```dart
class ScanOrchestrator {
  final List<IScanner> _pipeline;

  /// Default MVP pipeline: just MlKit
  ScanOrchestrator.mvp() : _pipeline = [MlKitScanner()];

  /// Phase 2 pipeline: TfLite crop → MlKit → Gemini fallback
  ScanOrchestrator.full({required String geminiApiKey})
      : _pipeline = [
          TfLiteRegionScanner(),
          MlKitScanner(),
          GeminiFlashScanner(apiKey: geminiApiKey),
        ];

  /// Runs the pipeline, returning the first confident result.
  Future<ScanResult> process(File imageFile) async {
    ScanResult? best;
    for (final scanner in _pipeline) {
      final result = await scanner.scan(imageFile);
      if (result.isComplete && result.isPlausible && result.confidence >= 0.75) {
        return result;
      }
      if (best == null || result.confidence > best.confidence) {
        best = result;
      }
    }
    return best!;
  }
}
```

---

## 5. MVP Scanner: MlKitScanner

### 5.1 Image Preprocessing

```dart
import 'package:image/image.dart' as img;

Future<File> preprocessForOcr(File source) async {
  final bytes = await source.readAsBytes();
  img.Image? image = img.decodeImage(bytes);
  if (image == null) throw Exception('Cannot decode image');

  image = img.grayscale(image);
  image = img.adjustColor(image, contrast: 1.5, brightness: 1.1);
  image = img.convolution(image, filter: [
    0, -1, 0,
    -1, 5, -1,
    0, -1, 0,
  ], div: 1);

  final dir = await getTemporaryDirectory();
  final outFile = File('${dir.path}/preprocessed_ocr.jpg');
  await outFile.writeAsBytes(img.encodeJpg(image, quality: 95));
  return outFile;
}
```

### 5.2 Label Proximity Matching Logic

```dart
class MlKitScanner extends IScanner {
  @override
  ScannerType get type => ScannerType.mlKit;

  static const _systolicLabels = [
    'sys', 'syst', 'systolic', 'mmhg',
  ];
  static const _diastolicLabels = [
    'dia', 'dias', 'diastolic', 'diast',
  ];
  static const _pulseLabels = [
    'pulse', 'pr', 'hr', 'heart rate', 'puls', 'bpm',
    '脈拍', '心率', 'nadi',
  ];

  @override
  Future<ScanResult> scan(File imageFile) async {
    final preprocessed = await preprocessForOcr(imageFile);
    final inputImage = InputImage.fromFile(preprocessed);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognized = await recognizer.processImage(inputImage);
    await recognizer.close();

    final numbers = <_NumberBlock>[];
    final labels = <_LabelBlock>[];

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim().toLowerCase();
        final box = line.boundingBox;

        if (RegExp(r'^\d{2,3}$').hasMatch(text)) {
          numbers.add(_NumberBlock(
            value: int.parse(text),
            box: box,
            confidence: line.confidence ?? 0.8,
          ));
        }

        final labelType = _classifyLabel(text);
        if (labelType != null) {
          labels.add(_LabelBlock(type: labelType, box: box));
        }
      }
    }

    // Strategy 1: Label proximity
    final assigned = _assignByProximity(numbers, labels);

    // Strategy 2: Positional fallback
    if (assigned.systolic == null || assigned.diastolic == null) {
      return _assignByPosition(numbers, assigned);
    }

    return assigned;
  }

  ScanResult _assignByProximity(
    List<_NumberBlock> numbers,
    List<_LabelBlock> labels,
  ) {
    int? systolic, diastolic, pulse;
    double minConfidence = 1.0;

    for (final label in labels) {
      _NumberBlock? closest;
      double closestDist = double.infinity;

      for (final num in numbers) {
        final dist = _distance(label.box, num.box);
        if (dist < closestDist) {
          closestDist = dist;
          closest = num;
        }
      }

      if (closest != null) {
        switch (label.type) {
          case _VitalType.systolic:
            systolic = closest.value;
            minConfidence = min(minConfidence, closest.confidence);
          case _VitalType.diastolic:
            diastolic = closest.value;
            minConfidence = min(minConfidence, closest.confidence);
          case _VitalType.pulse:
            pulse = closest.value;
            minConfidence = min(minConfidence, closest.confidence);
        }
      }
    }

    return ScanResult(
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      confidence: minConfidence,
      source: ScannerType.mlKit,
    );
  }

  /// Fallback: largest number = systolic, next = diastolic, smallest = pulse.
  ScanResult _assignByPosition(
    List<_NumberBlock> numbers,
    ScanResult partial,
  ) {
    if (numbers.length < 2) {
      return partial.copyWith(confidence: 0.3);
    }

    final sorted = [...numbers]
      ..sort((a, b) => b.box.height.compareTo(a.box.height));

    return ScanResult(
      systolic: partial.systolic ?? sorted[0].value,
      diastolic: partial.diastolic ?? (sorted.length > 1 ? sorted[1].value : null),
      pulse: partial.pulse ?? (sorted.length > 2 ? sorted[2].value : null),
      confidence: 0.6,
      source: ScannerType.mlKit,
    );
  }
}
```

---

## 6. Phase 2 Scanner Stubs

### 6.1 TfLiteRegionScanner

```dart
/// Phase 2: Uses a custom-trained TFLite MobileNet-SSD model to detect
/// regions of interest (systolic, diastolic, pulse) as bounding boxes,
/// then crops and passes each region to MlKitScanner.
class TfLiteRegionScanner extends IScanner {
  @override
  ScannerType get type => ScannerType.tflite;

  @override
  Future<ScanResult> scan(File imageFile) async {
    // TODO Phase 2:
    // 1. Load assets/models/bp_region_detector.tflite
    // 2. Run inference → bounding boxes for SYS/DIA/PULSE regions
    // 3. Crop each region
    // 4. Pass each crop to MlKitScanner
    // 5. Merge into one ScanResult
    throw UnimplementedError('TfLiteRegionScanner: Phase 2');
  }
}
```

### 6.2 GeminiFlashScanner

```dart
/// Phase 2: Calls Gemini Flash via ASP.NET Core backend proxy
/// (API key never exposed in client app).
class GeminiFlashScanner extends IScanner {
  final String _backendUrl;

  GeminiFlashScanner({required String backendUrl})
      : _backendUrl = backendUrl;

  @override
  ScannerType get type => ScannerType.geminiFlash;

  @override
  Future<ScanResult> scan(File imageFile) async {
    // TODO Phase 2:
    // 1. Base64 encode imageFile
    // 2. POST to $backendUrl/api/scan/gemini with {image: base64}
    // 3. Backend calls Gemini Flash with structured JSON prompt:
    //    "Extract systolic, diastolic, pulse from this BP monitor image.
    //     Return: {\"systolic\": int|null, \"diastolic\": int|null, \"pulse\": int|null}"
    // 4. Parse response into ScanResult
    throw UnimplementedError('GeminiFlashScanner: Phase 2');
  }
}
```

---

## 7. Data Layer

### 7.1 Database Schema (drift / SQLite)

```dart
@DataClassName('Reading')
class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().withDefault(const Constant('default'))();
  DateTimeColumn get measuredAt => dateTime()();
  IntColumn get systolic => integer().nullable()();
  IntColumn get diastolic => integer().nullable()();
  IntColumn get pulse => integer().nullable()();
  TextColumn get sourceType => textEnum<ScannerType>()();
  TextColumn get deviceLabel => text().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get ocrConfidence => real().nullable()();
  BoolColumn get isManuallyEdited => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

### 7.2 Repository Interface

```dart
abstract class IReadingRepository {
  Future<void> saveReading(Reading reading);
  Future<void> updateReading(Reading reading);
  Future<void> deleteReading(int id);
  Stream<List<Reading>> watchAllReadings();
  Future<List<Reading>> getReadingsInRange(DateTime from, DateTime to);
  Future<Reading?> getLatestReading();
  Future<Map<String, double>> getAverages({int lastDays = 30});
}
```

---

## 8. Screens & UI Specification

### 8.1 Design System

```dart
ThemeData buildTheme(ColorScheme? dynamicScheme, Brightness brightness) {
  final colorScheme = dynamicScheme ??
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B6CA8), // Medical blue
        brightness: brightness,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    typography: Typography.material2021(),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerLow,
    ),
  );
}
```

**Typography scale (Material 3):**
| Usage | Style |
|---|---|
| Reading values (120/80) | `displaySmall` — bold |
| Category labels (Systolic) | `labelLarge` — medium |
| Date/time | `bodySmall` |
| Chart axis labels | `labelSmall` |
| Section headers | `titleMedium` |

**Colour semantics for blood pressure:**
| Category | Systolic | Diastolic | Colour |
|---|---|---|---|
| Normal | < 120 | < 80 | `Colors.green` |
| Elevated | 120–129 | < 80 | `Colors.amber` |
| High Stage 1 | 130–139 | 80–89 | `Colors.orange` |
| High Stage 2 | ≥ 140 | ≥ 90 | `Colors.red` |
| Crisis | > 180 | > 120 | `Colors.red.shade900` |

---

### 8.2 Camera Screen

**Intent:** Full-screen camera, single button to capture.

```
┌──────────────────────────┐
│  ✕                    ⚙  │  ← AppBar (transparent)
│                          │
│    ┌────────────────┐    │
│    │                │    │  ← Guide frame (animated dashes)
│    │  Position your │    │
│    │  device here   │    │
│    │                │    │
│    └────────────────┘    │
│                          │
│   ⚡ Flash    🖼 Gallery  │
│                          │
│        ⬤ CAPTURE        │  ← Large FAB
└──────────────────────────┘
```

**Behaviours:**
- Guide frame pulses green when image is stable (accelerometer)
- Flash toggle for dark screens
- Gallery access for importing existing photos
- Auto-capture option (settings): fires after 2s of stability

---

### 8.3 Review Screen

**Intent:** Show extracted values, allow correction before saving.

```
┌──────────────────────────┐
│  ← Review Reading        │
├──────────────────────────┤
│  ┌────────────────────┐  │
│  │ [photo thumbnail]  │  │
│  └────────────────────┘  │
│                          │
│  Detected by: ML Kit  ✓  │
│                          │
│  ┌──────┐ ┌──────┐       │
│  │  120 │ │  80  │  72   │  ← Editable number fields
│  │ SYS  │ │ DIA  │  PR   │
│  └──────┘ └──────┘       │
│                          │
│  🔴 Hypertension Stage 1  │
│                          │
│  Notes: _______________  │
│                          │
│  [   SAVE READING   ]    │
│  [ Retake Photo     ]    │
└──────────────────────────┘
```

**Behaviours:**
- Each value tappable → numeric keyboard
- Values outside valid ranges show warning icon
- If `confidence < 0.75`: banner "Low confidence — please check values"
- Save button disabled until all 3 values present and plausible

---

### 8.4 Dashboard Screen

**Intent:** At-a-glance health status.

```
┌──────────────────────────┐
│  PulseSnap          ☰   │
├──────────────────────────┤
│  Latest Reading          │
│  ┌────────────────────┐  │
│  │  120 / 80   ❤ 72  │  │  ← Hero card, colour-coded
│  │  Normal            │  │
│  │  Today, 08:32      │  │
│  └────────────────────┘  │
│                          │
│  Last 30 Days            │
│  ┌────────────────────┐  │
│  │ [FL Chart          │  │  ← 3 line series: SYS, DIA, Pulse
│  │  LineChart]        │  │    reference lines at 120/80
│  └────────────────────┘  │
│                          │
│  Averages                │
│  SYS: 118  DIA: 76  PR: 70│
│                          │
│  [+ NEW READING]         │
└──────────────────────────┘
```

**Chart spec (fl_chart LineChart):**
- Series: Systolic (blue), Diastolic (teal), Pulse (orange)
- X-axis: dates formatted `dd MMM`
- Y-axis: 40–200, gridlines at 80/120
- Reference lines: y=120 (normal SYS), y=80 (normal DIA)
- Touch: vertical tooltip showing all 3 values
- Animated on load (800ms ease-in-out)

---

### 8.5 History Screen

- `SliverAppBar` with search bar
- Filter chips: `Today` | `7 Days` | `30 Days` | `All`
- `SliverList` of `ReadingListTile`:
  - Left: colour dot + date/time
  - Centre: `SYS / DIA  ❤ PR`
  - Right: chevron → detail screen
- Swipe-to-delete with undo `SnackBar`

---

### 8.6 Calendar Screen

**Package:** `table_calendar ^3.2.0`

```
┌──────────────────────────┐
│  ← Calendar              │
├──────────────────────────┤
│  May 2026                │
│  Mo Tu We Th Fr Sa Su    │
│   1  2  3  4  5  6  7   │
│  ...                     │  ← Days with readings: coloured dot
├──────────────────────────┤
│  18 May — 2 readings     │
│  ┌────────────────────┐  │
│  │ 08:32  120/80  ❤72 │  │
│  ├────────────────────┤  │
│  │ 20:15  118/78  ❤68 │  │
│  └────────────────────┘  │
└──────────────────────────┘
```

**Calendar dot colours:**
- Green: all readings Normal
- Amber: at least one Elevated
- Red: at least one High

---

### 8.7 Reading Detail Screen

- Large value display (hero typography)
- BP category chip
- Source badge (ML Kit / Manual / Gemini)
- OCR confidence indicator
- Notes field (inline editable)
- Edit button → numeric fields
- Delete → confirmation dialog

---

## 9. pubspec.yaml — Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  # OCR & Vision
  google_mlkit_text_recognition: ^0.15.0
  camera: ^0.11.0
  image_picker: ^1.1.0
  image: ^4.2.0

  # State Management & Navigation
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0
  go_router: ^14.0.0

  # Database
  drift: ^2.22.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0

  # Charts
  fl_chart: ^1.1.1

  # Calendar
  table_calendar: ^3.2.0

  # Networking (Phase 2)
  dio: ^5.7.0

  # Utilities
  intl: ^0.19.0
  uuid: ^4.5.0
  shared_preferences: ^2.3.0
  permission_handler: ^11.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^3.0.0
  build_runner: ^2.4.0
  drift_dev: ^2.22.0
  flutter_lints: ^4.0.0
  mocktail: ^1.0.0
```

---

## 10. Project Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── bp_colours.dart
│   ├── extensions/
│   │   └── datetime_extensions.dart
│   └── utils/
│       └── bp_category.dart
│
├── domain/
│   ├── models/
│   │   ├── reading.dart
│   │   └── scan_result.dart
│   ├── repositories/
│   │   └── i_reading_repository.dart
│   └── scanner/
│       ├── i_scanner.dart
│       ├── scan_orchestrator.dart
│       ├── mlkit_scanner.dart       ← MVP implementation
│       ├── tflite_scanner.dart      ← Phase 2 stub
│       └── gemini_scanner.dart      ← Phase 2 stub
│
├── data/
│   ├── database/
│   │   ├── app_database.dart
│   │   └── app_database.g.dart
│   └── repositories/
│       └── reading_repository.dart
│
├── features/
│   ├── camera/
│   │   ├── camera_screen.dart
│   │   └── camera_provider.dart
│   ├── review/
│   │   ├── review_screen.dart
│   │   └── review_provider.dart
│   ├── dashboard/
│   │   ├── dashboard_screen.dart
│   │   ├── dashboard_provider.dart
│   │   └── widgets/
│   │       ├── latest_reading_card.dart
│   │       └── trend_chart.dart
│   ├── history/
│   │   ├── history_screen.dart
│   │   ├── history_provider.dart
│   │   └── widgets/
│   │       └── reading_list_tile.dart
│   ├── calendar/
│   │   ├── calendar_screen.dart
│   │   └── calendar_provider.dart
│   ├── detail/
│   │   └── reading_detail_screen.dart
│   └── settings/
│       └── settings_screen.dart
│
└── providers.dart
```

---

## 11. Testing Strategy

| Layer | Type | Tool | Coverage Target |
|---|---|---|---|
| `IScanner` implementations | Unit | `flutter_test` + `mocktail` | 90%+ |
| `ScanOrchestrator` pipeline | Unit | `flutter_test` | 100% |
| `bp_category.dart` logic | Unit | `flutter_test` | 100% |
| `ReadingRepository` | Unit | `drift` in-memory | 80%+ |
| Dashboard / History screens | Widget | `flutter_test` | Key flows |
| Camera → Review flow | Integration | `integration_test` | Happy path |

### Key Unit Test Cases for MlKitScanner
- Correctly assigns values when all 3 labels are present
- Falls back to positional heuristic when no labels found
- Returns `confidence < 0.75` when only 2 values extracted
- Rejects implausible values (systolic = 9, pulse = 500)
- Handles CJK label synonyms (`脈拍` → pulse)

---

## 12. Platform Configuration

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-feature android:name="android.hardware.camera" android:required="false" />

<!-- Bundle OCR model at install time — eliminates first-launch download -->
<meta-data
    android:name="com.google.mlkit.vision.DEPENDENCIES"
    android:value="ocr" />
```

### iOS (`Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>PulseSnap needs camera access to photograph your blood pressure monitor.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>PulseSnap can import photos of your blood pressure monitor readings.</string>
```

---

## 13. Open Questions for Team

1. **Multi-user in MVP?** Schema supports `userId` but UI assumes single user.
2. **Photo retention**: Delete after extraction (privacy) or keep as proof?
3. **Gemini backend URL**: Existing ASP.NET Core service or separate endpoint?
4. **Minimum OS versions**: Recommend iOS 15+ / Android API 26+ for full ML Kit v2.
5. **Analytics location**: SQLite aggregate queries (drift) vs. Dart-side computation?

---

## 14. MVP Delivery Milestones

| Sprint | Deliverable |
|---|---|
| 1 | Project scaffold, theme, navigation, empty screens |
| 2 | `IScanner` interface, `MlKitScanner` with preprocessing, `ScanOrchestrator` |
| 3 | Camera screen + Review screen + save to SQLite |
| 4 | Dashboard screen with fl_chart line chart |
| 5 | History screen + Reading detail screen |
| 6 | Calendar screen + polish + dark mode |
| 7 | Testing, edge case handling, performance profiling |
| 8 | Beta release, internal testing |
