# EKB App — UI/UX & Design Guidelines

## 1. Design System & Typography
The application follows the **EKB Marketplace Design System** based on **Inter**:
- **Font Family:** `Inter` (weights: 400 Regular, 500 Medium, 600 SemiBold, 700 Bold). Avoid exceeding 3-4 weights per view.
- **Palette & Semantic Colors:**
  - `textPrimary`: `#111827` (headings, prices, titles, primary text)
  - `textSecondary`: `#6B7280` (descriptions, subtitles, secondary metadata)
  - `textMuted`: `#9CA3AF` (dates, city, timestamps, borders/placeholders)
  - `brandBlue`: `#1A56DB` (primary CTA buttons, active tab icons, highlights)
- **Hierarchy:**
  - Screen Titles: `28px, 700 Bold, line-height 34px`
  - Section Headings: `22px, 700 Bold, line-height 28px`
  - Item / Card Title: `16px, 600 SemiBold, line-height 22px` (max 2 lines, ellipsis)
  - Price: `20px, 700 Bold, line-height 24px` (visually dominant over title)
  - Body / Description: `14px, 400 Regular, line-height 20px` (max 2 lines)
  - Meta (City / Date): `13px, 500 Medium, line-height 18px`
  - Bottom Bar Labels: `12px, 500 Medium` (active: `brandBlue`, inactive: `textMuted`)

## 2. Spacing & Layout
- Use an **8-point grid** (4px, 8px, 12px, 16px, 24px, 32px).
- Internal card padding: typically 12–16px.
- List item separation / grid gap: 12–16px.
- Minimum interactive touch target: **48x48 dp** for all buttons, icons, and tap areas.
- Wrap content in `SafeArea` and handle responsive constraints with `LayoutBuilder` / `Flexible` to prevent `RenderFlex overflowed`.

## 3. Feedback & Micro-interactions
- **Loading:** Always use Shimmer / Skeleton cards resembling real content instead of bare circular progress indicators.
- **Empty States:** Provide a friendly vector icon/illustration, concise text, and a recovery/action button.
- **Transitions:** Animation durations between 200ms and 300ms using `Curves.easeInOutCubic` or `Curves.easeOut`.
- **Corner Radii & Shadows:** Soft rounded corners (12–16px for cards, 8–12px for inputs) and diffused, gentle elevation.
