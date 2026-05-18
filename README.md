# PulseSnap

Snap a photo of a blood-pressure monitor — get a structured reading.
Privacy-first: all data lives in a local SQLite database; the photo is
deleted immediately after extraction.

## MVP scope

- ML Kit on-device OCR with label-proximity + positional fallback
- Pluggable scanner pipeline (`IScanner` + `ScanOrchestrator`)
- SQLite via drift, single-user (multi-user schema-ready for Phase 2)
- Dashboard: latest reading hero card + 30-day fl_chart trend + averages
- History list with filter chips, search, swipe-to-delete + undo
- Calendar (`table_calendar`) with day-cell colour dot per AHA category
- Reading detail with in-place edit, OCR-confidence bar, delete
- Material 3 + dynamic colour, light/dark via OS

## Stack

Flutter 3.x · Dart 3.11 · Riverpod 3 · go_router · drift · fl_chart ·
table_calendar · google_mlkit_text_recognition · camera · image_picker

## Run

```bash
git clone --recurse-submodules <repo>      # or after a plain clone:
git submodule update --init --recursive    # pulls letsgodigital traineddata
flutter pub get
dart run build_runner build
flutter run                                # picks up the first available device
```

Min OS: iOS 15 / Android API 26. Bundle ID `com.pulsesnap.app`.

## OCR pipeline

PulseSnap uses two on-device OCR engines, run in order by
`ScanOrchestrator.mvp()`:

1. **Tesseract with `letsgodigital`** — purpose-built for 7-segment LCD
   displays. This is the primary engine. It reads the digits on the BP
   monitor screen.
2. **Google ML Kit (Latin)** — fallback for monitors whose chassis labels
   ("SYS", "DIA", "PR") are useful for proximity matching, or for any
   case where Tesseract returns nothing.

The orchestrator short-circuits on the first confident + plausible
result. If neither engine returns a full reading, the best partial
result is shown so the user can finish typing what was missed.

### Tesseract trained data

`letsgodigital.traineddata` is the community 7-seg model. It lives in a
git submodule under `vendor/display_ocr/` (upstream:
[arturaugusto/display_ocr](https://github.com/arturaugusto/display_ocr)).
The file is declared in `pubspec.yaml` as a Flutter asset and copied to
`<app-docs>/tessdata/letsgodigital.traineddata` on first scan, where the
Tesseract plugin reads it from.

If you clone without submodules, the submodule directory will be empty
and the scanner will log:

```
[PulseSnap Tesseract] traineddata missing — drop letsgodigital.traineddata into …
```

…and fall through to ML Kit. Run `git submodule update --init` to fix.

## Test

```bash
flutter test --timeout=30s         # 48 tests
flutter analyze
```

Coverage layers:

| Layer | File | What it covers |
|---|---|---|
| `bp_category` | `test/core/bp_category_test.dart` | AHA classification boundaries |
| `mlkit_logic` | `test/domain/mlkit_logic_test.dart` | Label classification (incl. CJK), proximity/positional assignment, plausibility |
| `ScanOrchestrator` | `test/domain/scan_orchestrator_test.dart` | Short-circuit, fallback, best-of |
| `ReadingRepository` | `test/data/reading_repository_test.dart` | drift CRUD + range + latest + averages |
| Dashboard stats | `test/features/dashboard_stats_test.dart` | 30-day window + averages |
| History filter | `test/features/history_filter_test.dart` | Filter chips + notes search |
| Calendar grouping | `test/features/calendar_provider_test.dart` | Day buckets + worst-category aggregation |
| ReviewForm widget | `test/features/review_screen_test.dart` | Low-confidence banner + save gating |

## Project layout

```
lib/
├── app.dart, main.dart, providers.dart
├── core/                 theme, bp_category, datetime extensions
├── domain/
│   ├── models/           scan_result.dart
│   ├── scanner/          IScanner, ScanOrchestrator, MlKit + Phase 2 stubs
│   └── repositories/     IReadingRepository
├── data/
│   ├── database/         drift schema + generated code
│   └── repositories/     ReadingRepository
└── features/
    ├── camera/           CameraScreen
    ├── review/           ReviewScreen + ReviewForm
    ├── dashboard/        Screen + stats + trend chart + latest card
    ├── history/          Screen + filter provider + tile
    ├── detail/           ReadingDetailScreen
    ├── calendar/         Screen + grouping provider
    └── settings/         SettingsScreen (+ debug seed)
```

## Phase 2 (post-MVP)

`TfLiteRegionScanner` and `GeminiFlashScanner` are stubbed and live behind
the same `IScanner` interface — wire them into `ScanOrchestrator.full()`
when the models / backend are ready.
