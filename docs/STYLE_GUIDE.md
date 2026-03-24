# GHISA — Visual Style Guide

## Design Philosophy

Dark, minimal, and data-forward — inspired by Oura Ring's premium aesthetic. Every screen should feel calm and focused, letting the data speak through subtle glowing accents on deep backgrounds.

---

## Color Palette

All colors are defined for dark theme. Light theme is not planned for V1.

### Backgrounds

| Role | Hex | Usage |
|------|-----|-------|
| Base | `#000000` | Root background, tab bar |
| Surface | `#1C1C1E` | Cards, sheets, grouped sections |
| Elevated | `#2C2C2E` | Modals, popovers, nested cards |
| Divider | `#38383A` | Separators, borders |

### Accent

| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#0A84FF` | Buttons, active tab, links, chart highlights |
| Primary Dimmed | `#0A84FF` at 15% opacity | Accent fills, tag backgrounds, subtle highlights |

Use one accent color everywhere. No secondary accent.

### Text

| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#FFFFFF` | Headlines, important values |
| Secondary | `#ABABAB` | Body text, descriptions |
| Tertiary | `#636366` | Placeholders, disabled text, captions |

### Semantic

| Role | Hex | Usage |
|------|-----|-------|
| Success | `#30D158` | Positive trends, completed states |
| Warning | `#FFD60A` | Caution indicators, moderate alerts |
| Error | `#FF453A` | Destructive actions, negative trends |

---

## Typography

Use SF Pro (system font) exclusively. Never bundle custom fonts.

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Large Title | 28pt | Bold | Screen titles (rare — only top-level) |
| Section Header | 20pt | Semibold | Section headings within a screen |
| Card Title | 17pt | Semibold | Card headlines, list item titles |
| Body | 15pt | Regular | Primary readable text |
| Callout | 14pt | Medium | Secondary info, supporting labels |
| Caption | 12pt | Regular | Timestamps, metadata, footnotes |
| Metric Value | 34pt | Bold | Hero numbers on insight cards |
| Metric Unit | 15pt | Regular | Units next to metric values (kg, kcal) |

### Rules
- Keep the type scale tight — avoid sizes outside this table
- Use `Font.system()` with explicit size and weight, or the corresponding SwiftUI `Font` style
- Numbers and metrics should use `.monospacedDigit()` for alignment

---

## Layout & Spacing

### Spacing Scale

Use multiples of 4pt for all spacing:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Tight gaps (icon-to-label, inline elements) |
| sm | 8pt | Within components (padding between stacked text) |
| md | 12pt | Default inner padding for cards |
| lg | 16pt | Gaps between cards, section spacing |
| xl | 24pt | Major section breaks |
| xxl | 32pt | Top/bottom screen margins |

### Cards

- Corner radius: **12pt**
- Background: Surface (`#1C1C1E`)
- Inner padding: 16pt
- Shadow: none (rely on background contrast, not shadows)
- Border: none by default; use `Divider` color for subtle outlines when needed

### Screen Layout

- Horizontal padding: 16pt (leading and trailing)
- Use `ScrollView` for all content screens
- Group related items in cards; don't float isolated labels
- Max content width: none (iPhone only, so full width minus padding)

---

## Components

### Buttons

| Type | Style |
|------|-------|
| Primary | Accent fill (`#0A84FF`), white label, 12pt corner radius, 48pt min height |
| Secondary | Transparent with accent border, accent label |
| Destructive | Error fill (`#FF453A`), white label |
| Text | No background, accent-colored label |

- Full-width buttons for primary actions at bottom of forms
- Inline/compact buttons for secondary actions within cards

### Text Inputs

- Background: Elevated (`#2C2C2E`)
- Corner radius: 10pt
- Padding: 12pt horizontal, 14pt vertical
- Placeholder text: Tertiary color
- No visible border in default state; accent border on focus

### Bottom Tab Bar

- Background: Base (`#000000`) with subtle top divider
- 3 tabs: Insights, Train, Daily Log
- Active tab: accent color icon + label
- Inactive tab: Tertiary color icon + label
- SF Symbols for icons, `.medium` weight
- No labels if icons are self-explanatory — test both, prefer labels for V1

### Navigation

- Use SwiftUI `NavigationStack`
- Inline navigation title style (`.navigationBarTitleDisplayMode(.inline)`)
- Profile icon (top-right) opens as a `.sheet`
- Prefer push navigation for drill-downs, sheets for creation/editing flows

---

## Charts & Data Visualization

Inspired by Oura's clean, muted chart style.

### General Rules

- Default chart color: accent blue (`#0A84FF`)
- Use muted/dimmed versions for secondary data series
- Background: transparent (sits on card surface)
- No gridlines — use subtle horizontal reference lines only if needed
- Axis labels: Caption style, Tertiary color
- Keep chart chrome minimal — the data shape is the point

### Line Charts

- Line width: 2pt
- Area fill: accent at 10-15% opacity (gradient to transparent)
- Data points: hidden by default, show on interaction
- Use smooth interpolation (`.catmullRom`)

### Bar Charts

- Corner radius on bars: 4pt (top only)
- Bar width: ~60% of available space
- Single color: accent blue
- Comparison bars: accent blue vs Tertiary (`#636366`)

### Interaction

- Tap/drag to reveal tooltip with exact value
- Highlight selected data point with a subtle glow or enlarged dot
- Keep animations smooth and brief (0.2s ease-out)

---

## Icons

- Use **SF Symbols** exclusively — no custom icon assets
- Default weight: `.medium`
- Default rendering: `.monochrome`
- Size: match the text style they sit beside (e.g., 17pt icon next to Body text)
- Active/selected state: accent color
- Inactive state: Tertiary color
- Use semantic symbols where possible (`plus`, `chevron.right`, `flame.fill`, `chart.line.uptrend.xyaxis`)

---

## Motion & Feedback

### Haptics

| Event | Haptic |
|-------|--------|
| Button tap | `.light` impact |
| Toggle/switch | `.light` impact |
| Successful action (save, complete) | `.success` notification |
| Error/validation failure | `.error` notification |
| Long press trigger | `.medium` impact |
| Pull to refresh | `.light` impact |

### Transitions

- Screen transitions: system default (push/pop, sheet presentation)
- Content appearance: fade in with slight upward translate (0.25s, ease-out)
- Card expansion: spring animation (response: 0.35, damping: 0.8)
- Avoid bouncy or playful animations — keep motion subtle and purposeful

### Loading States

- Use skeleton views (rounded rects in Elevated color) for content loading
- Subtle shimmer animation on skeletons (optional, keep it muted)
- Inline spinners for action feedback (e.g., saving), not full-screen overlays

---

## Implementation Notes

- Define all colors in a `Theme` struct or enum in `Utils/Theme.swift` using `Color(hex:)` extension
- Reference colors by semantic name (`Theme.surface`, `Theme.accent`) — never hardcode hex in views
- Spacing tokens should also be centralized (`Theme.Spacing.md`, etc.)
- All of the above values are starting points — adjust during implementation if something feels off on device
