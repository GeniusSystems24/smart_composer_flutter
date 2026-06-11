# GeniusLink Design System

GeniusLink is a bilingual (English + Arabic) enterprise resource planning (ERP) and accounting product. It is built around precise, audit-grade financial operations — journal entries, inventory issuance, store and account management, inter-account settlements, and the supporting balance / documents / audit trails that go with them.

The visual identity is a **precision instrument**: high-contrast dark default with a parallel light theme, a single dominant electric-royal-blue accent, restrained color outside of semantic status, monospace numerics, and section cards marked by a 4 px colored bar to denote intent (identity, ledger, notes). Every screen is bilingual — English fields and Arabic fields sit side-by-side with mirrored RTL placeholders.

---

## Index

| File / folder | Purpose |
|---|---|
| `README.md` | This file — brand context, content + visual foundations, iconography |
| `SKILL.md` | Cross-compatible Agent Skill manifest (use as a Claude Code skill) |
| `colors_and_type.css` | All design tokens — colors, type, spacing, radii, shadows + base classes |
| `assets/` | Logo marks, icons (SVG) extracted from Figma |
| `assets/icons/` | Line icons (1.5 px stroke, rounded caps) extracted from Figma |
| `preview/` | Design system showcase cards rendered for the DS tab |
| `ui_kits/genius_link/` | Pixel-faithful component recreations + clickable demo |
| `sources/` | Source notes referencing the original Figma file |

### Sources of truth

- **Figma file:** "GeniusLink - creatation screens.fig" — mounted as a virtual filesystem during creation (81 frames on Page-1: Create-Account, Create-Account-Group, Create-Store, Create-Deposit, Issue-Inventory, Opening-Journal-Entry, Financial-Operation-Details, Transfer-Inventory, Account-Group-Details, Store-Details — each in Desktop + Mobile variants, with both dark and light theme).
- **Uploaded logos:** `uploads/icon.png` (color cube mark) and `uploads/accountingSystemLogoWhite.png` (white-on-transparent cube mark) — copied into `assets/`.
- The Figma uses placeholder copy ("Architectural Ledger ERP • Precision System v4.2") in footers; the **brand name is GeniusLink**, established by the user. Treat the placeholder strings as design specimens, not real product copy.

---

## CONTENT FUNDAMENTALS

GeniusLink copy is **clinical, instructive, and operator-facing**. The reader is an accountant, a store manager, or an admin who needs to perform a precise transaction. The voice is impersonal — neither "I" nor "you" appear; instead the UI names what the user is *defining*, *issuing*, or *posting*.

### Voice & tone

- **Operator-facing, not marketing.** Every label is the name of a noun or verb in the financial domain. "Issue Inventory", "Create Account Group", "Opening Journal Entry", "Inter-Account Settlement".
- **No persona, no greetings.** Never "Welcome back", never "Let's get started". The system is a tool, not a companion.
- **Imperatives for actions.** Buttons read `Create Store`, `Issue Inventory`, `Create Entry`, `Back to List`, `Cancel`, `Delete`. Always Title Case.
- **Descriptive subtitles.** Beneath every section heading sits a one-line plain-English explainer: *"Define store name and location information"*, *"Add any notes about this account group"*. These are written in third-person imperative.
- **No emoji. No exclamation points.** The brand never uses either — emoji would be incompatible with the audit-grade feel.

### Casing

- Page titles: **Title Case** — *Create Store*, *Opening Journal Entry*.
- Buttons: **Title Case** — *Create Group*, *Back to List*.
- Eyebrow / breadcrumb / form label / table header: **ALL CAPS, tracking ~0.05em** — `STORES & PRODUCTS • STORES`, `NAME ENGLISH *`, `TOTAL DEBITS`.
- Footer micro-copy: **ALL CAPS** — `© 2024 ARCHITECTURAL LEDGER ERP • SYSTEM STATUS: OPERATIONAL`.
- Body copy and placeholders: **Sentence case** — *"Add internal notes about this store's operational status or architectural details…"*.

### Punctuation

- Breadcrumbs separate with a centered bullet: `BANKING • LOCAL TRANSFERS • DETAILS`.
- Required fields take a trailing red asterisk: `Name English *` (the `*` is colored `--gl-danger-500`).
- Placeholders use **example** framing: *"e.g. Downtown Central Store"*, *"e.g. Main Branch"*, *"e.g. Current Assets"*. Always lowercase `e.g.` then a single space, then the example in title case.
- Note placeholders trail off with a horizontal ellipsis: *"Add notes about this account…"* — never three dots.

### Bilingual rules

- **English on the left, Arabic on the right.** Both fields are always equal width and share one row in a 2-column grid.
- Arabic placeholders mirror English ones: *"e.g. Downtown Central Store"* sits opposite *"مثال: متجر وسط المدينة الرئيسي"*.
- Arabic labels lead with `الاسم بالعربية *` (Name in Arabic). The whole Arabic field renders RTL; the English field renders LTR.
- Page titles can have an inline Arabic translation in blue tertiary text: `Opening Journal Entry قيد افتتاحي`.
- Numbers stay in Western digits regardless of language (`$5,240.00`, `JV-2024-0042`).

### Numeric & financial copy

- Currency renders with a leading symbol and 2-decimal precision: `$5,240.00`, `$0.00`. Saudi Riyal is shown via the code `SAR` to the right of the amount in tables.
- Positive deltas: leading `+` and green color (`+5,000.00`). Negative deltas: leading `-` and red (`-5,000.00`).
- Serial / reference IDs are monospace and dot-segmented: `TR-9042`, `JV-2024-0042`, `INV-ISS-2024-0089`, `a7f8…b161` (truncated hash with horizontal ellipsis).
- Tables always show **#** (1, 2, 3…) as a left gutter column in the same monospace face.

### Example copy snippets (verbatim from the system)

> `STORES & PRODUCTS • STORES`
> **Create Store**
> *Define store name and location information*
> NAME ENGLISH \*   `e.g. Downtown Central Store`
>
> ---
>
> `BANKING • LOCAL TRANSFERS • DETAILS`
> **Inter-Account Settlement [TR-9042]**
> "Operational adjustment for quarterly reconciliation. The transfer ensures synchronization between domestic holdings and international reserves prior to the Q4 audit window."
>
> ---
>
> `© 2024 ARCHITECTURAL LEDGER ERP • PRECISION SYSTEM`
> `SYSTEM STATUS   DOCUMENTATION   AUDIT LOG`

---

## VISUAL FOUNDATIONS

### Color philosophy

The palette is **one bright primary against a quiet neutral spine**. The blue `#4A7CFF` is the only fully saturated color used outside of semantic states; everything else is grayscale. Green (`#1DB88A`), orange (`#F97316`), and red (`#EF4444`) appear *only* as semantic signals (success / notes / danger) — never as decoration.

- **Dominant background — DARK is default.** `#111318` (page) / `#1E2025` (card). Dark-first because the product is used in long, focused sessions and the high-contrast text on near-black reduces glare in spreadsheet-heavy work.
- **Light theme is offered in parity.** Same hierarchy on `#F7F8FA` page + `#FFFFFF` cards. Both themes coexist in the same Figma frames — every screen has a dark + light pairing.
- **No gradients.** Backgrounds are flat. The only soft-light is the card shadow `0 25px 50px -12px rgba(0,0,0,0.25)` that lifts panels off the page in dark mode.
- **No transparency tricks, no glass-morphism.** Borders are solid hairlines (`rgba(67,70,84,0.4)` in dark, `#E2E8F0` in light). The product reads as engraved metal plates, not floating glass.

### Typography

Three faces, no exceptions.

- **Manrope** — display only. Used at one size: H1 page titles, 26 px / weight 700 / -0.025 em tracking. Also for the embossed page-name watermark.
- **Inter** — the workhorse. Section headings (16 px / 700), body (14 px / 400), eyebrows & labels (11 px / 700 ALL CAPS, 0.05–0.15 em tracking depending on role), placeholder + caption (12 px / 400).
- **JetBrains Mono** — numerics & references. Currency, serials, audit-log timestamps, IPs.
- **Noto Naskh Arabic** — Arabic glyphs (substitution flagged — Figma source uses a placeholder face).

Tracking is intentional: tiny labels get wide spacing (0.05 em for form labels, 0.15 em for breadcrumbs). H1 is the only thing that tightens (-0.025 em).

### Spacing & layout

- **4 px base unit.** Used scales: 4, 8, 12, 16, 24, 32, 40, 64, 80.
- **8 px card radius** is the default. Inputs and buttons are 4 px. Section-marker bars are 12 px (fully rounded pills inside the card).
- **Section card** is the fundamental unit. Padding `24 24 40 24`. Internal gap `32 px`. Cards stack vertically with `32 px` between them.
- **Form grid** is two-column. `24 px` column gap, `24 px` row gap. English on left, Arabic on right.
- **Page layout** is centered to a `680 px` content column with `300 px` left/right margins on desktop (giving room for the wallpaper watermark glyphs).

### Section markers — the brand's signature device

Every card opens with a **4 × 40 px vertical pill bar** in one of three colors, separated from the heading by 16 px. This is the most distinctive GeniusLink visual:

- 🟦 **Blue** — primary identity / definition / details sections.
- 🟢 **Green** — financial / balance / ledger / transfer sections.
- 🟠 **Orange** — notes / compliance / documentation / additional info.

The bar is `border-radius: 12 px`, `width: 4 px`, `height: ~40 px` (matches the height of the heading + subtitle stack).

### Wallpaper / page art

The dark page has a **single oversized faded glyph** (e.g. a storefront pictogram, a drafting compass) embossed at ~5 % opacity in the bottom corner. It functions as a quiet visual identifier for the page context — not a decorative pattern. On lighter views it appears as a fine line drawing.

Also, the page background carries the page name itself as 300 px Manrope text at `rgba(255,255,255,0.05)` — pure embossed type, not decoration.

### Borders, shadows, elevation

- **Hairlines** — 1 px solid, low-opacity. Dark: `rgba(67,70,84,0.4)`. Light: `#E2E8F0`.
- **Card shadow** — `0 25px 50px -12px rgba(0,0,0,0.25)` in dark; subtler `0 1px 2px + 0 8px 24px` stack in light. Cards lift; everything else sits flat.
- **No inner shadows.** No emboss. No press-state shadow shifts.
- **Focus states** use a 2 px solid blue outline outside the input (no inner glow). Tab order is critical for keyboard-heavy data entry.

### Hover & press states

- **Buttons hover:** primary blue lightens by ~6 % (toward `#5E8DFF`); secondary outlined buttons fill their background with `--gl-hover`.
- **Buttons press:** scale 0.98 + the blue darkens toward `#3D6DEB`.
- **Table rows hover:** background shifts to `--gl-hover` (`#2F3540` dark / `#EEF1F7` light). No row scale or shadow.
- **Icon buttons (edit / delete in detail headers):** background tints to `--gl-input-bg` on hover; delete icon trades neutral for danger red.
- **Disabled:** 40 % opacity, no pointer events. No grayscale filter.

### Motion

GeniusLink is **a slow, deliberate interface**. Animations are subtle:

- **Default transition:** `150 ms ease` on color / background.
- **Card expand/collapse** (e.g. "Group Details" accordion): `200 ms ease-out` on max-height + opacity.
- **Page transitions:** instant. No route-level animation — this is a tool, not a story.
- **No bounces, no springs, no parallax.** The only easing curves are `ease` and `ease-out`. No `cubic-bezier` exuberance.

### Imagery

Imagery is sparse — this is a back-office product, not a marketing site. The only photographic image type that appears is **document thumbnails in attachment lists** (PDF / DOCX / JPG icons next to a small file-meta line). When real imagery is required it is grayscale or cool-toned, never warm — to match the cool-blue accent system.

### Component vocabulary (quick reference)

- **Cards** — `8 px` radius, hairline border, large shadow in dark, 24 px internal padding, gap of 32 px between sections inside.
- **Section header** — colored 4 px bar + heading 16 px/700 + subtitle 12 px/400 in `--gl-fg-3`.
- **Inputs** — 40 px tall, 4 px radius, 16 px horizontal padding, label uppercase 11/700 above with 8 px gap; arabic input mirrors English (right-aligned).
- **Buttons primary** — `#4A7CFF` solid bg, white text, 8–16 px vertical/horizontal padding, 4 px radius, Inter 14/600.
- **Buttons secondary** — transparent bg, 1 px border `--gl-border-strong`, current text color.
- **Buttons icon** — 32×32 px, current bg, 4 px radius, icon 16×16 stroked.
- **Status pills** — 12 px radius, `8/4` padding, uppercase 10/700, semantic-colored bg `+ 20%` lightness behind colored text.
- **Tables** — column headers in the uppercase label style, rows separated by hairlines, first column is `#` index in mono, last column right-aligned (typically Date or Total).
- **Footer** — flat row of uppercase labels: brand string left, action links right, all 11/700 in `--gl-fg-4`.

---

## ICONOGRAPHY

GeniusLink uses **outlined line icons** with a consistent 1.5 px stroke, rounded caps, and rounded line joins. Icons are typically rendered at 16 × 16 px or 20 × 20 px and always inherit `currentColor` so they tint to the surrounding text.

- Stored locally as **SVGs** under `assets/icons/` (extracted from the Figma source). The Figma frames carry the following types we've captured: storefront, drafting compass, scanner / barcode, generic vector glyphs.
- Where a richer icon set is needed for the UI kit, **Lucide Icons** is the chosen CDN substitute — it matches the GeniusLink stroke style (1.5 px, rounded, outlined) almost perfectly. Loaded via `<script src="https://unpkg.com/lucide@latest"></script>` in `ui_kits/genius_link/index.html`. **FLAGGED**: when production icons land, replace Lucide references with the in-house SVGs.
- **No icon font.** The product uses individual SVG files in production (per Figma export structure).
- **No emoji. No Unicode glyph icons** (e.g. ✓, ✕, →). The only Unicode marks that appear are the bullet `•` (separator in breadcrumbs and footers) and the horizontal ellipsis `…` (truncations).
- **Logo:** the GeniusLink cube mark (`assets/logo-mark.png` color, `assets/logo-mark-white.png` white) — a 3D isometric cube with a violet accent face. Used at 24–32 px in app chrome; never recolored, never placed on busy imagery.
- **Watermark glyphs:** the oversized page-corner pictograms (~150 × 150 px at 5 % opacity) are also from this icon family — store, compass, scanner — selected to match the page context.

---

## Caveats & substitutions

- **Arabic font:** the Figma binary attributes Arabic text to `FreeSerif`, which is a pseudocode artifact from the file extraction. The Arabic font ships as `Noto Naskh Arabic` from Google Fonts pending the real spec — please confirm or supply the production face.
- **Brand vs. placeholder copy:** Figma frames contain *"Architectural Ledger ERP • Precision System v4.2"* in chrome / footers. The brand established by the user is **GeniusLink**; all UI kit recreations swap this in.
- **Icon set:** local SVGs from Figma cover storefront / scanner / compass. Lucide Icons is loaded as a CDN-side substitute for everything else — verify before production.
- **No image assets** are present in the Figma file beyond the cube logo. No marketing photography or illustration is part of this system.
