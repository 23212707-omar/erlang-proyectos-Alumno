---
name: Alumbrado Público Tijuana
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#44474d'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#74777e'
  outline-variant: '#c4c6ce'
  surface-tint: '#4b5f7f'
  primary: '#000d21'
  on-primary: '#ffffff'
  primary-container: '#0c2340'
  on-primary-container: '#778bad'
  inverse-primary: '#b3c7ec'
  secondary: '#4059aa'
  on-secondary: '#ffffff'
  secondary-container: '#8fa7fe'
  on-secondary-container: '#1d3989'
  tertiary: '#180900'
  on-tertiary: '#ffffff'
  tertiary-container: '#371c00'
  on-tertiary-container: '#ac8159'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#b3c7ec'
  on-primary-fixed: '#031c38'
  on-primary-fixed-variant: '#334766'
  secondary-fixed: '#dce1ff'
  secondary-fixed-dim: '#b6c4ff'
  on-secondary-fixed: '#00164e'
  on-secondary-fixed-variant: '#264191'
  tertiary-fixed: '#ffdcbf'
  tertiary-fixed-dim: '#efbd90'
  on-tertiary-fixed: '#2d1600'
  on-tertiary-fixed-variant: '#613f1d'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  title-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1.5rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system establishes a rigorous, functional, and authoritative institutional interface for public works administration and mobile field crew operations within the Municipality of Tijuana. 

### Design Philosophy
The aesthetic follows a functional municipal standard: high-contrast, structured, and resilient under adverse environmental conditions (direct sunlight on mobile devices, low-light night shifts). The visual tone conveys civic responsibility, operational efficiency, and institutional stability without ornamental distractions.

### Audience & Environment
- **Field Crews & Technicians:** Operators using handheld devices outdoors, requiring large tap targets, immediate readability, explicit semantic state labeling, and zero reliance on color alone.
- **Municipal Coordinators & Dispatchers:** Operators managing dense ticket volumes, dispatch queues, and infrastructure verification.
- **Citizens:** Users submitting and tracking service reports who demand clarity, trust, and transparent service delivery.

## Colors

The palette is engineered for institutional legitimacy and strict accessibility (WCAG 2.1 AAA compliance for core text, AA minimum for status badges).

### Palette Architecture
- **Primary Institutional (`#0C2340`):** Deep civic navy utilized for top application headers, high-level navigation, primary buttons, and key structural landmarks.
- **Secondary Civic (`#1E3A8A`):** Interactive accents, active focus rings, and secondary action highlights.
- **Surfaces & Backgrounds:** Crisp `#FFFFFF` for data-entry cards and elevated dialogs; neutral `#F8FAFC` and `#F1F5F9` for canvas backing, segment grouping, and layout separation.
- **Text & Hierarchy:** `#0F172A` (Slate 900) ensures maximum contrast on white/neutral backgrounds. Supporting metadata uses `#334155` (Slate 700).

### Immutable Semantic Status System
Status indicators are standardized across all modules and must always combine container color, border tint, text tint, and a formal text label:
- **Reportada (Unattended Fault):** Critical red (`#DC2626`) on pale red ground (`#FEF2F2`) with defining border (`#FCA5A5`).
- **Asignada (Crew Dispatched):** Amber/Orange (`#D97706`) on light gold ground (`#FFFBEB`) with defining border (`#FCD34D`).
- **Reparada (Closed/Resolved):** Forest green (`#16A34A`) on mint ground (`#F0FDF4`) with defining border (`#86EFAC`).

## Typography

Inter serves as the primary typographic foundation across all breakpoints. Its tall x-height, neutral letterforms, and distinct numerical glyphs make it exceptionally resilient for reading pole IDs, serial numbers, geocoordinates, and incident timestamps.

### Hierarchy & Mobile Scaling
- **Headlines:** Reserved for dashboard section headers and main report views. Scaled down on viewports under 600px via `headline-lg-mobile` to prevent overflow and unintended line breaking.
- **Labels & Monospace Accents:** Priority tags, crew call signs, and serial IDs must be displayed in `label-sm` or `label-md` with uppercase styling and slight tracking to maximize instant comprehension on ruggedized mobile screens.
- **Body Copy:** Standard descriptions and address instructions use `body-md` and `body-lg` with generous line heights to preserve scanning cadence.

## Layout & Spacing

The system adopts a fluid-first, mobile-centric architecture optimized for handheld field devices (base width 390px) while effortlessly stretching to support multi-column desktop operations desks.

### Responsive Breakpoints & Grid Model
- **Mobile Handheld (360px – 599px):** 4-column fluid layout. Canvas margin: `1rem` (`margin-mobile`), gutter: `0.75rem`. Elements span all 4 columns for single-column linear workflows. All primary touch targets adhere to a minimum 48px square boundary.
- **Tablet / Field Pad (600px – 1023px):** 8-column layout. Canvas margin: `1.5rem`, gutter: `1rem`. Dual-pane views (incident list on the left, map view on the right).
- **Desktop Command (1024px+):** 12-column layout. Margin: `2rem`, gutter: `1.5rem`. Fixed side navigation and persistent multi-panel operational views.

### Rhythmic Scale
Spacing adheres to a strict 4px/8px modular scale. Spacing tokens govern card padding, form group separation, and status chip stacking.

## Elevation & Depth

To preserve outdoor readability and maintain a formal institutional aesthetic, elevation relies primarily on structural borders and subtle tonal layering rather than heavy drop shadows.

### Elevation Levels
- **Level 0 (Flat Ground):** Used for base screens and page backdrops (`#F8FAFC`). No shadow, no border.
- **Level 1 (Structural Card / Surface):** Pure white background (`#FFFFFF`) framed by a solid `1px` border (`#E2E8F0`). Used for list items, standard data blocks, and ticket summaries.
- **Level 2 (Interactive Floating / Active State):** A high-definition, subtle outline (`1px solid #CBD5E1`) paired with a minimal ambient shadow: `0 1px 3px 0 rgba(15, 23, 42, 0.08), 0 1px 2px -1px rgba(15, 23, 42, 0.08)`. Used for active inspection cards and dropdown sheets.
- **Level 3 (Modal / Field Dialog):** `0 10px 15px -3px rgba(12, 35, 64, 0.12), 0 4px 6px -4px rgba(12, 35, 64, 0.08)` bordered by `#CBD5E1`. Used for confirmation modals and camera inspection overlays.

## Shapes

The shape system utilizes a conservative "Soft" geometry (`roundedness: 1`). Corner radii are deliberate, clean, and restrained, reflecting civic seriousness and structural durability.

### Application Rules
- **Base Components (Inputs, Buttons, Cards, Banners):** Standard radius of `0.25rem` (4px).
- **Surface Groups & Modals (`rounded-lg`):** Radius of `0.5rem` (8px).
- **Status Tags & Priority Chips:** Fixed at `0.25rem` (4px) to retain an authoritative, badge-like profile. Pill shapes are forbidden to prevent decorative dilution.

## Components

### Buttons
- **Primary:** Institutional Navy (`#0C2340`) background, `#FFFFFF` text, `4px` radius. Minimum height of 48px on mobile for gloved or one-handed field use.
- **Secondary:** Surface `#FFFFFF`, border `1.5px solid #0C2340`, text `#0C2340`.
- **Destructive:** Background `#DC2626`, text `#FFFFFF`. Used strictly for incident cancellations or critical error reports.
- **States:** Active and pressed states shift color by 10% darkness. Focused states show a `2px` offset outline in `#1E3A8A`.

### Status Badges & Priority Chips
Information must never rely exclusively on color. Every indicator must display both an icon and an explicit alphanumeric label.

#### Status Badges (Reportada, Asignada, Reparada)
- **Reportada:** Background `#FEF2F2`, border `1px solid #FCA5A5`, text `#DC2626`. Text label: `REPORTADA`.
- **Asignada:** Background `#FFFBEB`, border `1px solid #FCD34D`, text `#D97706`. Text label: `ASIGNADA`.
- **Reparada:** Background `#F0FDF4`, border `1px solid #86EFAC`, text `#16A34A`. Text label: `REPARADA`.

#### Priority Tags (Visual distinction + Geometrical Glyph + Label)
- **Alta:** Background `#FEF2F2`, text `#DC2626`, border `1px solid #FCA5A5`. Label format: `[▲ ALTA]`.
- **Media:** Background `#FFFBEB`, text `#D97706`, border `1px solid #FCD34D`. Label format: `[■ MEDIA]`.
- **Baja:** Background `#F1F5F9`, text `#334155`, border `1px solid #CBD5E1`. Label format: `[● BAJA]`.

### Form Fields & Inputs
- **Inputs:** White background, minimum 48px height, `1px solid #CBD5E1` border, `4px` radius. Internal padding: `0.75rem 1rem`.
- **Focus:** `2px solid #1E3A8A` border with zero drop shadow.
- **Field Labels:** Bold, `14px` (`#0F172A`), uppercase or sentence case with explicit `* Requerido` markers.
- **Error States:** Border `2px solid #DC2626` with explicit assistive text below.

### Cards & Ticket Lists
- **Incident Card:** White background with a `1px solid #E2E8F0` border. The card header features the Ticket ID (`#0F172A`, bold) on the left, with the Status Badge and Priority Chip aligned on the right. Card body displays the physical street address, colonias, and pole number.
- **Touch Target:** The full card serves as a tap target on mobile, with a dedicated direct-call or navigate button separated by a divider.

### Checkboxes & Radios
- Size: 20px x 20px minimum bounding box with a 48px touch target wrapper.
- Border: `2px solid #334155`.
- Selected State: Background `#0C2340`, border `#0C2340`, with an unmistakable high-contrast white tick or dot.