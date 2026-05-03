# TODOs

## 1. WCAG Contrast Audit

Audit all schedule badge color + white text combinations for WCAG AA compliance (4.5:1 minimum for small text).

**Likely failures:**
- `#33CCCC` (teal, "Every N") — estimated ~2.5:1 with white
- `#84CC16` (lime, "Daily") — estimated ~2.8:1 with white

**Fix options:**
- Use darker variant of each color
- Switch badge text to dark/black for low-contrast backgrounds
- Add a semi-transparent dark overlay behind text

**Reference:** Schedule Badge Colors table in `DESIGN.md`

## 2. Design System Consolidation

Decide on a single canonical design system source. Currently both are used interchangeably across 35+ views:

- **DesignKit** (external SPM package, `mayankgandhi/DesignKit`) — shared across projects
- **TickerDesignSystem** (internal, `TickerCore/Sources/TickerCore/UI/TickerDesignSystem.swift`) — app-specific

**Options:**
1. Make DesignKit the single source, remove TickerDesignSystem
2. Make TickerDesignSystem the single source, use DesignKit only for shared components
3. Keep both but add automated sync validation (design token tests)

**Current mitigation:** `DesignTokenValidationTests.swift` validates token parity at build time.
