---
version: alpha
name: PulseSnap
description: A personal blood pressure and heart rate monitoring app for Android and iOS, built in Flutter with Material Design 3.
colors:
  # MD3 base palette
  primary: "#6B5EAE"
  primary-container: "#E6E0FF"
  on-primary: "#FFFFFF"
  on-primary-container: "#22005D"
  secondary: "#944A6B"
  secondary-container: "#FFD9E2"
  on-secondary: "#FFFFFF"
  on-secondary-container: "#3E001D"
  tertiary: "#49A17A"
  tertiary-container: "#C3F0DA"
  on-tertiary-container: "#00391F"
  surface: "#FAF9FF"
  surface-variant: "#EEECF5"
  on-surface: "#1C1B1F"
  on-surface-variant: "#49454F"
  outline: "#79747E"
  outline-variant: "#CAC4D0"
  error: "#BA1A1A"
  error-container: "#FFDAD6"
  # Vital: blood pressure severity tokens
  vital-bp-low: "#2F80ED"
  vital-bp-normal: "#27AE60"
  vital-bp-elevated: "#F2C94C"
  vital-bp-high1: "#F2994A"
  vital-bp-high2: "#EB5757"
  vital-bp-crisis: "#8B1E3F"
  # Vital: heart rate severity tokens
  vital-hr-very-low: "#3F8CFF"
  vital-hr-low: "#56CCF2"
  vital-hr-normal: "#27AE60"
  vital-hr-high1: "#F2C94C"
  vital-hr-high2: "#F2994A"
  vital-hr-high3: "#EB5757"
  # Status card background tokens (pastel tints per SeverityLevel)
  status-info-bg: "#EAF3FF"
  status-success-bg: "#EAF8EF"
  status-caution-bg: "#FFF7E0"
  status-warning-bg: "#FFEFE2"
  status-danger-bg: "#FDECEC"
  status-urgent-bg: "#F8E6EC"
typography:
  reading-display:
    fontFamily: Roboto
    fontSize: 40px
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: -0.02em
  reading-unit:
    fontFamily: Roboto
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.0
  headline-lg:
    fontFamily: Roboto
    fontSize: 32px
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Roboto
    fontSize: 24px
    fontWeight: 700
    lineHeight: 1.25
  headline-sm:
    fontFamily: Roboto
    fontSize: 20px
    fontWeight: 600
    lineHeight: 1.3
  body-lg:
    fontFamily: Roboto
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  body-md:
    fontFamily: Roboto
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  body-sm:
    fontFamily: Roboto
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.4
  label-lg:
    fontFamily: Roboto
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.0
    letterSpacing: 0.01em
  label-md:
    fontFamily: Roboto
    fontSize: 12px
    fontWeight: 500
    lineHeight: 1.0
    letterSpacing: 0.05em
  label-caps:
    fontFamily: Roboto
    fontSize: 11px
    fontWeight: 600
    lineHeight: 1.0
    letterSpacing: 0.12em
rounded:
  none: 0px
  sm: 4px
  md: 12px
  lg: 16px
  xl: 24px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.full}"
    padding: 16px
    height: 48px
  button-primary-hover:
    backgroundColor: "#8F86CC"
  button-secondary:
    backgroundColor: "{colors.primary-container}"
    textColor: "{colors.on-primary-container}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.full}"
    padding: 16px
    height: 48px
  button-secondary-hover:
    backgroundColor: "#D0CCFF"
  button-text:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.full}"
    padding: 16px
    height: 48px
  chip-selection:
    backgroundColor: "{colors.surface-variant}"
    textColor: "{colors.on-surface-variant}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 8px
    height: 32px
  chip-selection-active:
    backgroundColor: "{colors.primary-container}"
    textColor: "{colors.on-primary-container}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 8px
    height: 32px
  chip-status:
    backgroundColor: "{colors.surface-variant}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  card:
    backgroundColor: "{colors.surface-variant}"
    rounded: "{rounded.lg}"
    padding: 16px
  card-reading-info:
    backgroundColor: "{colors.status-info-bg}"
    rounded: "{rounded.lg}"
    padding: 16px
  card-reading-normal:
    backgroundColor: "{colors.status-success-bg}"
    rounded: "{rounded.lg}"
    padding: 16px
  card-reading-caution:
    backgroundColor: "{colors.status-caution-bg}"
    rounded: "{rounded.lg}"
    padding: 16px
  card-reading-warning:
    backgroundColor: "{colors.status-warning-bg}"
    rounded: "{rounded.lg}"
    padding: 16px
  card-reading-danger:
    backgroundColor: "{colors.status-danger-bg}"
    rounded: "{rounded.lg}"
    padding: 16px
  card-reading-urgent:
    backgroundColor: "{colors.status-urgent-bg}"
    rounded: "{rounded.lg}"
    padding: 16px
  fab:
    backgroundColor: "{colors.secondary}"
    textColor: "{colors.on-secondary}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.full}"
    padding: 16px
    height: 56px
  # Vital status chips — BP (dot color per severity level)
  chip-status-info:
    backgroundColor: "{colors.status-info-bg}"
    textColor: "{colors.on-surface}"
    dotColor: "{colors.vital-bp-low}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  chip-status-normal:
    backgroundColor: "{colors.status-success-bg}"
    textColor: "{colors.on-surface}"
    dotColor: "{colors.vital-bp-normal}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  chip-status-caution:
    backgroundColor: "{colors.status-caution-bg}"
    textColor: "{colors.on-surface}"
    dotColor: "{colors.vital-bp-elevated}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  chip-status-warning:
    backgroundColor: "{colors.status-warning-bg}"
    textColor: "{colors.on-surface}"
    dotColor: "{colors.vital-bp-high1}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  chip-status-danger:
    backgroundColor: "{colors.status-danger-bg}"
    textColor: "{colors.on-surface}"
    dotColor: "{colors.vital-bp-high2}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  chip-status-urgent:
    backgroundColor: "{colors.status-urgent-bg}"
    textColor: "{colors.vital-bp-crisis}"
    dotColor: "{colors.vital-bp-crisis}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  # Vital status chips — HR
  chip-hr-very-low:
    backgroundColor: "{colors.status-info-bg}"
    textColor: "{colors.on-surface}"
    dotColor: "{colors.vital-hr-very-low}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  chip-hr-low:
    backgroundColor: "{colors.status-caution-bg}"
    textColor: "{colors.on-surface}"
    dotColor: "{colors.vital-hr-low}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  chip-hr-normal:
    backgroundColor: "{colors.status-success-bg}"
    textColor: "{colors.on-surface}"
    dotColor: "{colors.vital-hr-normal}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  chip-hr-high1:
    backgroundColor: "{colors.status-caution-bg}"
    textColor: "{colors.on-surface}"
    dotColor: "{colors.vital-hr-high1}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  chip-hr-high2:
    backgroundColor: "{colors.status-warning-bg}"
    textColor: "{colors.on-surface}"
    dotColor: "{colors.vital-hr-high2}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  chip-hr-high3:
    backgroundColor: "{colors.status-danger-bg}"
    textColor: "{colors.on-surface}"
    dotColor: "{colors.vital-hr-high3}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 6px
    height: 28px
  # Chart line colours
  chart-line-sys:
    backgroundColor: "{colors.vital-bp-high2}"
  chart-line-dia:
    backgroundColor: "{colors.tertiary}"
  chart-line-pulse:
    backgroundColor: "{colors.secondary-container}"
  chart-area:
    backgroundColor: "{colors.primary-container}"
  chart-threshold:
    backgroundColor: "{colors.outline-variant}"
  # Input / form
  input-field:
    backgroundColor: "{colors.surface-variant}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-md}"
    rounded: "{rounded.full}"
    padding: 12px
    height: 48px
  input-field-outline:
    backgroundColor: "{colors.outline}"
  input-field-error:
    backgroundColor: "{colors.error-container}"
    textColor: "{colors.error}"
  # Misc tokens referenced in prose
  nav-indicator:
    backgroundColor: "{colors.primary-container}"
    textColor: "{colors.on-primary-container}"
  crisis-banner:
    backgroundColor: "{colors.status-urgent-bg}"
    textColor: "{colors.vital-bp-crisis}"
    rounded: "{rounded.md}"
  secondary-surface:
    backgroundColor: "{colors.secondary-container}"
    textColor: "{colors.on-secondary-container}"
  tertiary-surface:
    backgroundColor: "{colors.tertiary-container}"
    textColor: "{colors.on-tertiary-container}"
  tertiary-icon:
    backgroundColor: "{colors.tertiary-container}"
    textColor: "{colors.on-tertiary-container}"
---

# PulseSnap Design System

## Overview

PulseSnap is a calm, trustworthy health-monitoring app for tracking blood pressure and resting heart rate. The visual language must feel precise enough to convey clinical data clearly, and approachable enough not to provoke anxiety during routine use. Users range from people managing hypertension daily to those doing occasional wellness checks; the UI communicates severity through colour and layout hierarchy without being alarming.

The app is built with Flutter and follows Material Design 3 principles throughout. It makes extensive use of tonal colour surfaces: reading cards are tinted with the appropriate severity background so users develop an intuitive visual vocabulary for their health data over time. The overall aesthetic is soft, pastel, and airy — generous whitespace, pill-shaped interactive elements, and large legible numbers. Nothing is sharp or sterile.

**Platform:** Flutter (Android + iOS)
**Design system:** Material Design 3
**Tone:** Calm, clear, trustworthy. Never clinical-cold or alarming.

## Colors

The palette uses a muted periwinkle violet as its primary colour and a dusty rose as its secondary. These provide clear interactive affordance without competing with the semantic vital colours that carry health meaning. Vital colours are reserved exclusively for severity indication and must never be reused for chrome, branding, or decoration.

### Brand palette

- **Primary (#6B5EAE):** Muted periwinkle violet, darkened to meet WCAG AA (≈4.9:1 against white). Used for filled primary buttons, active navigation indicators, and focus rings. A step deeper than the current flat lavender — reads clearly as actionable without being heavy.
- **Primary Container (#E6E0FF):** Soft pastel lavender. The dominant button surface in the app — used for tonal (secondary) buttons, selected chips, and the active bottom-nav pill. This matches the current UI approach and works well; keep it.
- **Secondary (#944A6B):** Dusty mauve-rose, darkened to meet WCAG AA (≈5.4:1 against white). Reserved for the FAB ("New Reading") to give the primary recording action warm visual prominence and a subtle heart-health association. Used sparingly.
- **Secondary Container (#FFD9E2):** Very light rose. Available for secondary tonal surfaces or badges.
- **Tertiary (#49A17A):** Muted sage green. Used for chart DIA line and informational healthy-state UI contexts. Distinct from `vital-bp-normal` / `vital-hr-normal` — those are for severity chips only.
- **Surface (#FAF9FF):** Near-white with a faint violet tint. Warmer than pure white, consistent with MD3 tonal surface model.
- **Surface Variant (#EEECF5):** Slightly cooler tinted surface for cards, the calendar container, and non-reading card containers. Provides subtle depth without shadows.

### Button colour guidance

The current implementation uses a single filled-tonal style (light lavender) for all buttons. The recommended hierarchy below differentiates button visual weight:

- **Primary action** — one per screen (e.g. "Generate Preview", "Save", "Confirm"): use `button-primary` — filled `primary` (#6B5EAE) with white text.
- **Secondary / selection actions** (e.g. date-range chips, source toggles, multi-option pickers): use `button-secondary` — tonal `primary-container` (#E6E0FF) with `on-primary-container` text. This matches the current style and is correct for these contexts.
- **FAB / New Reading**: use `fab` component — `secondary` (#944A6B) fill with `on-secondary` (#FFFFFF) text. This separates the core recording action visually from navigation and filter controls.
- **Destructive / low-emphasis actions**: use `button-text` — `surface` background with `primary` text colour.

### Vital status colours

These tokens encode clinical severity defined in `Docs/02-pulsesnap-tech-spec-updates.md`. Never repurpose them for UI chrome.

**Blood pressure:**

- **vital-bp-low (#2F80ED):** Calm blue — below typical range, informational tone.
- **vital-bp-normal (#27AE60):** Green — within healthy range.
- **vital-bp-elevated (#F2C94C):** Amber — above normal, not yet hypertension.
- **vital-bp-high1 (#F2994A):** Orange — High Stage 1, attention warranted.
- **vital-bp-high2 (#EB5757):** Red — High Stage 2, consistent action recommended.
- **vital-bp-crisis (#8B1E3F):** Deep crimson — hypertensive crisis, emergency messaging tier. Never used for general UI.

**Heart rate:**

- **vital-hr-very-low (#3F8CFF):** Bright blue — very low resting pulse.
- **vital-hr-low (#56CCF2):** Sky blue — slightly low / borderline.
- **vital-hr-normal (#27AE60):** Green — normal resting range (60–100 bpm).
- **vital-hr-high1 (#F2C94C):** Amber — mildly elevated.
- **vital-hr-high2 (#F2994A):** Orange — clearly elevated.
- **vital-hr-high3 (#EB5757):** Red — very high resting pulse.

### Status card backgrounds

Pastel tint surfaces mapped 1:1 to the `SeverityLevel` enum:

- **status-info-bg (#EAF3FF):** `info` — bp-low, hr-very-low.
- **status-success-bg (#EAF8EF):** `normal` — all values in healthy range.
- **status-caution-bg (#FFF7E0):** `caution` — bp-elevated, hr-low, hr-mildly-high.
- **status-warning-bg (#FFEFE2):** `warning` — High Stage 1.
- **status-danger-bg (#FDECEC):** `danger` — High Stage 2.
- **status-urgent-bg (#F8E6EC):** `urgent` — hypertensive crisis.

All `status-*-bg` tokens are designed to pass WCAG AA contrast (4.5:1) when paired with `on-surface` (#1C1B1F). Do not invert to white text on these backgrounds.

## Typography

PulseSnap uses Roboto throughout, consistent with Material Design 3 defaults on Android. The key typographic tension is between the reading display (large numeric values) and contextual metadata. Numbers are always set in `reading-display` (40px/700) to ensure instant legibility at a glance — BP readings are the primary content.

Section headers (LATEST, LAST 30 DAYS, AVERAGES) use `label-caps` (11px/600, 0.12em tracking) in all-caps, matching the current UI treatment. This is the only place all-caps is used.

- **reading-display (40px/700):** Systolic/diastolic numbers, pulse. The hero content of every reading card.
- **reading-unit (14px/400):** mmHg and bpm — always inline-baseline beside the display figure, never stacked.
- **headline-lg (32px/700):** Onboarding, modal titles.
- **headline-md (24px/700):** Reading detail screen heading.
- **headline-sm (20px/600):** Top app bar titles (History, Export, Settings).
- **body-lg (16px/400):** General body content.
- **body-md (14px/400):** Card secondary text — date/time, tag list.
- **body-sm (12px/400):** Helper text, PDF footer disclaimer.
- **label-lg (14px/500):** Button labels, FAB label.
- **label-md (12px/500):** Status chip labels, tag chip labels.
- **label-caps (11px/600, 0.12em tracking):** Section headers — uppercase only, never used elsewhere.

## Layout

PulseSnap follows a single-column, full-bleed card layout on mobile. Content uses a consistent 16px horizontal margin. The bottom navigation bar is always fixed. The main content area is a scrollable card list.

**Horizontal margin:** 16px both sides.
**Section gap:** 24px between distinct content sections.
**Card internal padding:** 16px.
**Card gap (list):** 12px between adjacent reading rows.
**Bottom nav height:** 80px including system gesture area padding.
**Calendar widget:** Full width within margins, 16px internal padding, 40dp day-cell height.

Spacing scale usage:
- `xs` (4px): micro-gaps within chips, dot indicator margins.
- `sm` (8px): icon-to-label gap inside buttons and chips.
- `md` (16px): standard horizontal margin, card padding, inter-element spacing.
- `lg` (24px): section separation.
- `xl` (32px): screen top padding.
- `xxl` (48px): large modal / bottom-sheet top padding.

## Elevation & Depth

PulseSnap uses tonal elevation rather than drop shadows, consistent with MD3. Reading cards are distinguished from the page surface by their semantic background colour, not by shadow. The one exception is the FAB, which receives MD3 level 3 elevation.

- **Level 0:** App background (`surface` — #FAF9FF).
- **Level 1:** Cards, calendar container (`surface-variant` or a `status-*-bg` tint).
- **Level 2:** Bottom navigation bar (subtle tonal shift, no explicit shadow).
- **Level 3:** FAB only (MD3 standard elevation shadow).
- **Modals / bottom sheets:** MD3 default scrim with level-2 tonal surface.

Never add custom drop shadows to reading cards or list items. Severity is communicated by the tinted background, not by depth.

## Shapes

PulseSnap uses a consistently rounded, expressive shape vocabulary. No sharp corners appear anywhere in the UI.

- **Reading cards, chart container, calendar widget:** `rounded.lg` (16px).
- **Primary and secondary buttons:** `rounded.full` (9999px) — pill shape.
- **FAB:** `rounded.full`.
- **Status chips (e.g. "High Stage 1", "Pulse · Normal"):** `rounded.full`.
- **Tag chips:** `rounded.full`.
- **Search / tag input field:** `rounded.full`.
- **Bottom nav active indicator pill:** `rounded.full`.
- **Crisis banner (persistent top alert):** `rounded.md` (12px) — slightly contained, visually distinct from cards.
- **Chart axis labels, PDF table cells:** `rounded.sm` (4px) — the only context where near-sharp corners are used.

## Components

### Reading card

The core UI component. Each card's background is determined by the reading's `SeverityLevel`, mapped to a `card-reading-*` component token. All foreground text uses `on-surface` (#1C1B1F) — the status backgrounds are all light pastels that pass AA contrast with dark text. Do not use white text on status backgrounds.

Card structure (top to bottom):

1. **Values row:** `reading-display` for systolic/diastolic, `reading-unit` ("mmHg") inline; heart icon (20px, `on-surface-variant`) + pulse value in `headline-md` + `reading-unit` ("bpm"). Trailing chevron icon (›) right-aligned for navigation.
2. **Status chips row:** BP status chip (primary classification, left) + HR status chip (secondary, right). Chips use the `chip-status` component token. Each chip has a filled dot (8px) in the corresponding `vital-*` colour preceding the label.
3. **Date/time row:** `body-md`, `on-surface-variant` colour.

### Status chip

`chip-status` component. Background is the appropriate `status-*-bg` at ~60% opacity over the card background. A solid 8px circle in the `vital-*` severity colour precedes the label. Text uses `label-md`, `on-surface` colour.

Never use the full vital colour as the entire chip fill — only the indicator dot. The chip background should be a very light tint, not a saturated colour.

Example mappings:
- `bpHigh1` reading → `status-warning-bg` chip background, `vital-bp-high1` (#F2994A) dot, "High Stage 1" label.
- `hrNormal` reading → `status-success-bg` chip background, `vital-hr-normal` (#27AE60) dot, "Pulse · Normal" label.

### Buttons

All buttons: `rounded.full`, `label-lg` typography, 48px height minimum. Icon buttons (FAB, "Generate Preview", "New Reading") place a 20px icon 8px to the left of the label text.

See the Colors section for full button hierarchy and when to use each variant.

### Tag chips

Input chips using `chip-selection` at rest and `chip-selection-active` when selected. `rounded.full`, `label-md`, 32px height. Multiple selection is permitted simultaneously. The `custom...` chip opens an inline text field without a separate modal when possible.

### Bottom navigation bar

Three destinations: Home, History, Settings. Active item uses `primary-container` as a stadium-shape indicator behind the icon. Active icon colour: `on-primary-container`. Inactive icon colour: `on-surface-variant`. Show label only for the active item (MD3 navigation bar default).

### Calendar widget

Full width within page margins. Background `surface-variant`, `rounded.lg`. Today's date: `primary`-filled circle, `on-primary` text. Dates with readings: small `secondary` dot below the day number. Selected date: `primary-container` background, `on-primary-container` text. Month navigation arrows: `on-surface-variant`.

### Trend chart

- **SYS line:** Solid, `vital-bp-high2` (#EB5757).
- **DIA line:** Dashed, `tertiary` (#49A17A).
- **Pulse line:** Dotted, `secondary` (#B06885).
- **Chart area background:** `primary-container` at 25% opacity for a very soft tinted canvas.
- **Threshold reference lines:** Thin dashed `outline-variant` at systolic 120, 130, 140 and diastolic 80, 90.

Chart container: `card` component token (`surface-variant`, `rounded.lg`, 16px padding).

### Export / date-range screen

Date range options use `button-secondary` (tonal lavender chips). The currently selected option renders with `chip-selection-active` styling (bold weight, `primary-container` background). "Generate Preview" is the screen's single primary action — use `button-primary` (filled `primary`, white text). Source checkboxes follow MD3 checkbox defaults with `primary` as the checked colour.

### Crisis banner

When the latest reading is `urgent` (`bpCrisis`), display a persistent, non-dismissible banner at the top of the Home screen. Background: `status-urgent-bg`, border: 1.5px solid `vital-bp-crisis`, corner radius `rounded.md`. Text: "Seek immediate medical attention" in `label-lg` / `vital-bp-crisis`. Include a phone/emergency icon leading the message. This banner cannot be dismissed until a new non-crisis reading is saved.

## Do's and Don'ts

- Do use `vital-*` colour tokens exclusively for severity indicators. Never repurpose them for brand, buttons, or decorative elements.
- Do use `reading-display` (40px/700) for every BP and pulse numeric value. Legibility at a glance is the primary design requirement.
- Do derive each reading card's background from `status-*-bg` via the `SeverityLevel` — never hardcode colours directly against raw numeric thresholds in the UI layer.
- Do show the non-dismissible crisis banner whenever the latest reading is `bpCrisis`. This is a safety requirement.
- Do maintain WCAG AA contrast (4.5:1 minimum) for all text on status background colours. The `status-*-bg` tokens are calibrated to pass with `on-surface` (#1C1B1F) foreground.
- Do keep the FAB ("New Reading") visible and accessible from the Home screen at all times. It is the entry point to the core user action.
- Don't add drop shadows to reading cards or list rows. Tonal surface colour provides sufficient depth.
- Don't mix vital severity colours with interactive brand colours on the same component.
- Don't use `label-caps` (all-caps) outside of section header labels (LATEST, AVERAGES, etc.).
- Don't reduce button or FAB touch targets below 48px height. Many users check readings in low-dexterity contexts.
- Don't use `vital-bp-crisis` (#8B1E3F) as a general accent, button highlight, or chart colour. It is reserved for crisis-state UI only.
- Don't omit the disclaimer footer ("This report contains home-monitored readings…") from any exported PDF page.
- Don't use white text on `status-*-bg` card backgrounds. All status backgrounds are light pastels designed for dark-on-light legibility.
