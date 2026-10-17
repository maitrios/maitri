# maitri logo exploration: log

Issue k7lab/maitrios#41. Every image here, how it was made and what was decided about it. Any lettering a model drew is a placeholder; the wordmark stays typeset.

## Setup

- References rendered locally from the repo: `refs/heart-dark.png` (assets/brand/heart.svg on #0F0A18), `refs/heart-light.png` (#644AC9 on #F5F5F5), `refs/wordmark-amethyst.png` and `refs/wordmark-daybreak.png` (logo.txt through tools/brand.py's wordmark code), `refs/icon.png` (assets/brand/icon.svg).
- Drafts: `gemini-nano-banana-2.1`, 1K, two runs (a, b) per prompt. Finals: `gemini-3-pro-image` (Nano Banana Pro), 4K, with the picked draft as reference 1.
- FLUX 3 Image was skipped: there's no OPENROUTER_API_KEY in fnox.
- Spend: $12.16 over 102 calls (66 drafts, 36 Pro finals including redos), cap $25.
- Full prompt text for every image is in `prompts/<direction>/<id>.json`. Each prompt is built from shared blocks: brand line, a description of the references, the direction lead, the variant line, the palette, and a flat-vector rule block.

## Problems and fixes

- 7 of the first 27 Pro calls hit Gemini's spend-rate limit (429, shared account); retried one at a time.
- The first light finals took the dark draft as reference 1 and came back with a dark band bleeding in, and letter 1a turned into a different design. Fix: invert the dark final's lightness locally (ImageMagick HSL), feed that as the only reference, and ask Pro to clean it and set the daybreak palette. Rejected outputs are kept out of the branch.
- block 1a-light and letter 1a-light still came back with added fills and fake depth on the redo, so those two are local recolors of the dark final (grayscale through a #F5F5F5 / #B3A6E6 / #644AC9 CLUT), no model.
- tile 1a-light came back indigo instead of #644AC9; the heart fill was remapped locally.
- embrace 1b-dark first came back as a different, busier mark; redone with a note to keep only the two crescents.
- Light finals keep a faint lavender wash instead of flat #F5F5F5. The vector fixes that.

## heart: Open heart, refined

Sheet: `heart.jpg`. Aspect 1:1. References: refs/heart-dark.png.

Variants:

1. Keep the single rounded monoline, but tune it like a professional type designer would: optically even stroke, slightly fuller lobes, a softer rounded bottom point, and inward curls that end in round terminals facing each other like two people about to touch.
2. Make the stroke heavier and give it gentle contrast, thicker at the shoulders and thinner where the two curls meet the centre, so the open gap at the top feels like an invitation.
3. Draw the heart as one continuous unbroken line that starts at the bottom point, rises around the left lobe, makes a small loop at the top centre, and returns around the right lobe; calm and minimal.
4. Two separate rounded strokes, a left half and a right half, that do not quite touch at the top and the bottom, each half shaped like a gentle crescent; together they read as an open heart.
5. A filled solid heart silhouette with the open heart's inward curls carved into it as a narrow negative-space line from the top centre, so it reads boldly at 16 pixels and still shows the curl.

| image | model | refs | cost | decision |
|---|---|---|---|---|
| draft 1a | nano-banana-2.1 1K | refs/heart-dark.png | $0.049 | picked for a final: closest evolution of today's heart; the curls make the open gap feel deliberate |
| draft 1b | nano-banana-2.1 1K | refs/heart-dark.png | $0.050 | draft only |
| draft 2a | nano-banana-2.1 1K | refs/heart-dark.png | $0.049 | draft only |
| draft 2b | nano-banana-2.1 1K | refs/heart-dark.png | $0.047 | draft only |
| draft 3a | nano-banana-2.1 1K | refs/heart-dark.png | $0.051 | draft only |
| draft 3b | nano-banana-2.1 1K | refs/heart-dark.png | $0.052 | picked for a final: one line with a single loop at the top; the only heart that feels drawn by a person, and it keeps the open gap as a gesture |
| draft 4a | nano-banana-2.1 1K | refs/heart-dark.png | $0.052 | draft only |
| draft 4b | nano-banana-2.1 1K | refs/heart-dark.png | $0.044 | draft only |
| draft 5a | nano-banana-2.1 1K | refs/heart-dark.png | $0.052 | picked for a final: filled heart with carved curls; the strongest silhouette at small sizes |
| draft 5b | nano-banana-2.1 1K | refs/heart-dark.png | $0.049 | draft only |
| final 1a-dark | Nano Banana Pro 4K | draft heart/1a, refs/heart-dark.png | $0.246 | final, not shortlisted |
| final 3b-dark | Nano Banana Pro 4K | draft heart/3b, refs/heart-dark.png | $0.246 | shortlisted (Loop heart) |
| final 3b-light | Nano Banana Pro 4K | refs/inverted/heart-3b.png (local lightness inversion of the dark final) | $0.490 | shortlisted (Loop heart) |
| final 5a-dark | Nano Banana Pro 4K | draft heart/5a, refs/heart-dark.png | $0.246 | final, not shortlisted |

## lockup: Heart and wordmark lockup

Sheet: `lockup.jpg`. Aspect 16:9. References: refs/heart-dark.png, refs/wordmark-amethyst.png.

Variants:

1. Horizontal lockup: the open heart symbol on the left, the word 'maitri' in lowercase on the right in a friendly rounded geometric sans serif, the heart's stroke weight matching the letters.
2. Stacked lockup: the open heart centred above the word 'maitri' in lowercase, wide letter spacing, calm and balanced, like a boot screen logo.
3. The word 'maitri' in lowercase rounded sans serif where the dots over both letters i are replaced by two tiny open hearts; no separate symbol.
4. Horizontal lockup that keeps the chunky block terminal letters MAITRI from reference 2, refined and evenly spaced, with a small pixel-built version of the open heart before it.

| image | model | refs | cost | decision |
|---|---|---|---|---|
| draft 1a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.046 | picked for a final: the plain horizontal lockup the brand is missing; heart stroke matches the letters |
| draft 1b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.047 | draft only |
| draft 2a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.049 | draft only |
| draft 2b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.050 | picked for a final: stacked lockup for boot and login screens |
| draft 3a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.048 | draft only |
| draft 3b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.041 | picked for a final: hearts as the dots over both i's; warm with no separate symbol |
| draft 4a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.051 | draft only |
| draft 4b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.052 | draft only |
| final 1a-dark | Nano Banana Pro 4K | draft lockup/1a, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.247 | shortlisted (Heart + lowercase lockup) |
| final 1a-light | Nano Banana Pro 4K | refs/inverted/lockup-1a.png (local lightness inversion of the dark final) | $0.490 | shortlisted (Heart + lowercase lockup) |
| final 2b-dark | Nano Banana Pro 4K | draft lockup/2b, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.247 | final, not shortlisted |
| final 3b-dark | Nano Banana Pro 4K | draft lockup/3b, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.248 | final, not shortlisted |

## letter: Mark from the letterforms

Sheet: `letter.jpg`. Aspect 1:1. References: refs/heart-dark.png, refs/wordmark-amethyst.png.

Variants:

1. A lowercase letter m drawn as one rounded stroke, whose two arches swell into the two lobes of a heart and whose outer stems lean inward to meet at a soft point below, so it reads as both m and heart.
2. A monogram: a lowercase m whose middle stem dips down into a small heart-shaped notch, set inside a soft rounded square outline.
3. The two letters i in maitri reinterpreted as two simple standing figures, their round heads as dots, leaning toward each other so the space between them forms a heart.
4. A single geometric letter m built from two overlapping semicircular arches, where the overlap creates a small heart shape in the middle; minimal and balanced.
5. The open heart from reference 1 whose two inward curls continue downward and merge into one short vertical stem in the middle, turning the heart into a lowercase m with a pointed base; same even rounded stroke as reference 1, the stem ending in a round terminal about halfway down.
6. A filled solid heart silhouette with a single narrow slot cut from the top centre down to the middle, so the two lobes read as the arches of a lowercase m; bold enough for a favicon.

| image | model | refs | cost | decision |
|---|---|---|---|---|
| draft 1a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.054 | picked for a final: the open heart whose curls drop into the middle stem of an m; reads as heart first and m second |
| draft 1b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.053 | draft only |
| draft 2a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.056 | draft only |
| draft 2b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.055 | draft only |
| draft 3a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.061 | draft only |
| draft 3b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.058 | draft only |
| draft 4a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.054 | draft only |
| draft 4b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.055 | picked for a final: an M whose inner counter is a heart; bolder monogram |
| draft 5a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.044 | draft only |
| draft 5b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.047 | draft only |
| draft 6a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.056 | picked for a final: filled heart with a slot from the top; m-heart that survives 16 px |
| draft 6b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.050 | draft only |
| final 1a-dark | Nano Banana Pro 4K | draft letter/1a, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.248 | final, not shortlisted |
| final 1a-light | local recolor, no model | finals/letter/1a-dark.jpg | $0.492 | final, not shortlisted |
| final 4b-dark | Nano Banana Pro 4K | draft letter/4b, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.247 | final, not shortlisted |
| final 6a-dark | Nano Banana Pro 4K | draft letter/6a, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.246 | final, not shortlisted |

## block: Heart from the wordmark's blocks

Sheet: `block.jpg`. Aspect 1:1. References: refs/heart-dark.png, refs/wordmark-amethyst.png.

Variants:

1. A pixel heart on a coarse grid of square cells, keeping the open gap and inward curls at the top, with the wordmark's soft offset shadow in a deeper violet down and to the right.
2. An open heart outline drawn with chunky square pixels on a 13 by 11 grid, one cell thick, crisp and readable at 16 pixels, no shadow.
3. A filled pixel heart where each cell is a rounded square with tiny gaps between cells, like keys or terminal character cells, the top centre cell left empty to keep the heart open.
4. A heart drawn with terminal half-block and full-block shapes, slightly rounded corners on the outer cells only, warm rather than retro.

| image | model | refs | cost | decision |
|---|---|---|---|---|
| draft 1a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.048 | picked for a final: the heart rebuilt in the wordmark's block cells and offset shadow, so the two marks finally match |
| draft 1b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.044 | draft only |
| draft 2a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.046 | draft only |
| draft 2b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.045 | picked for a final: one-cell pixel outline; pixel-perfect at 16 px |
| draft 3a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.052 | picked for a final: rounded key-like cells; friendlier take on the grid |
| draft 3b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.049 | draft only |
| draft 4a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.048 | draft only |
| draft 4b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.050 | draft only |
| final 1a-dark | Nano Banana Pro 4K | draft block/1a, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.248 | shortlisted (Block heart) |
| final 1a-light | local recolor, no model | finals/block/1a-dark.jpg | $0.492 | shortlisted (Block heart) |
| final 2b-dark | Nano Banana Pro 4K | draft block/2b, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.247 | final, not shortlisted |
| final 3a-dark | Nano Banana Pro 4K | draft block/3a, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.247 | final, not shortlisted |

## embrace: Kinder abstract form

Sheet: `embrace.jpg`. Aspect 1:1. References: refs/heart-dark.png.

Variants:

1. Two soft crescent shapes leaning into each other like an embrace, the negative space between them forming a gentle heart.
2. Two cupped open hands drawn as simple rounded shapes, holding a small circle, minimal enough for a favicon.
3. Concentric rounded ripples spreading outward from a small open heart at the centre, kindness spreading outward, three rings, calm.
4. A sunrise: a half circle rising over a horizon line, the rays replaced by the two lobes of an open heart, minimal and geometric.
5. Two identical rounded comma-like shapes, mirror images facing each other, together forming an open heart with a small gap at the top and at the bottom; one flat color.

| image | model | refs | cost | decision |
|---|---|---|---|---|
| draft 1a | nano-banana-2.1 1K | refs/heart-dark.png | $0.051 | draft only |
| draft 1b | nano-banana-2.1 1K | refs/heart-dark.png | $0.047 | picked for a final: two crescents leaning in; abstract and calm, not a literal heart |
| draft 2a | nano-banana-2.1 1K | refs/heart-dark.png | $0.045 | draft only |
| draft 2b | nano-banana-2.1 1K | refs/heart-dark.png | $0.049 | draft only |
| draft 3a | nano-banana-2.1 1K | refs/heart-dark.png | $0.049 | draft only |
| draft 3b | nano-banana-2.1 1K | refs/heart-dark.png | $0.050 | draft only |
| draft 4a | nano-banana-2.1 1K | refs/heart-dark.png | $0.052 | picked for a final: the heart as a sunrise over the horizon; ties straight to daybreak |
| draft 4b | nano-banana-2.1 1K | refs/heart-dark.png | $0.048 | draft only |
| draft 5a | nano-banana-2.1 1K | refs/heart-dark.png | $0.048 | draft only |
| draft 5b | nano-banana-2.1 1K | refs/heart-dark.png | $0.048 | draft only |
| final 1b-dark | Nano Banana Pro 4K | draft embrace/1b, refs/heart-dark.png | $0.492 | final, not shortlisted |
| final 4a-dark | Nano Banana Pro 4K | draft embrace/4a, refs/heart-dark.png | $0.247 | final, not shortlisted |
| final 4a-light | Nano Banana Pro 4K | refs/inverted/embrace-4a.png (local lightness inversion of the dark final) | $0.491 | final, not shortlisted |

## computer: A kinder computer

Sheet: `computer.jpg`. Aspect 1:1. References: refs/heart-dark.png, refs/wordmark-amethyst.png.

Variants:

1. The open heart whose gap at the top holds a short vertical bar, so it reads both as a heart and as a power button symbol.
2. The open heart with a small solid rectangular text cursor block sitting inside it, like a blinking terminal cursor, off-centre to the lower right.
3. A terminal prompt chevron and underscore arranged so they form the outline of a heart, rounded line ends.
4. A rounded window frame with a thin title bar, and the open heart filling the window, simple and friendly.
5. The open heart where the two inward curls end just short of the centre and a short vertical bar stands in the gap, like the line of a power symbol; all one even rounded stroke, the bar not touching the outline.

| image | model | refs | cost | decision |
|---|---|---|---|---|
| draft 1a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.051 | picked for a final: the open gap becomes a power symbol; says 'a kinder computer' in one glyph |
| draft 1b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.046 | draft only |
| draft 2a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.048 | draft only |
| draft 2b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.048 | draft only |
| draft 3a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.055 | picked for a final: a prompt chevron and underscore that become the heart; nerdier and very maitri |
| draft 3b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.060 | draft only |
| draft 4a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.049 | picked for a final: the heart inside a window frame; reads as an OS at a glance |
| draft 4b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.046 | draft only |
| draft 5a | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.048 | draft only |
| draft 5b | nano-banana-2.1 1K | refs/heart-dark.png, refs/wordmark-amethyst.png | $0.052 | draft only |
| final 1a-dark | Nano Banana Pro 4K | draft computer/1a, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.247 | shortlisted (Power heart) |
| final 1a-light | Nano Banana Pro 4K | refs/inverted/computer-1a.png (local lightness inversion of the dark final) | $0.492 | shortlisted (Power heart) |
| final 3a-dark | Nano Banana Pro 4K | draft computer/3a, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.247 | final, not shortlisted |
| final 4a-dark | Nano Banana Pro 4K | draft computer/4a, refs/heart-dark.png, refs/wordmark-amethyst.png | $0.247 | final, not shortlisted |

## tile: App icon, 16 to 1024 px

Sheet: `tile.jpg`. Aspect 1:1. References: refs/icon.png, refs/heart-dark.png.

Variants:

1. A rounded square tile in deep violet #1D1729 fading to #0F0A18, with a bold filled heart in #B08CFF whose top keeps a small notch where the open heart's gap was; the heart fills most of the tile.
2. A full-bleed amethyst #B08CFF rounded square tile with the open heart cut out of it in #0F0A18, very thick stroke, simple enough for a browser tab.
3. A circular badge with a thick open heart, the heart stroke so heavy the inner space becomes a small teardrop; high contrast.
4. A rounded square tile with a soft gradient from #B08CFF at top to #6E52C9 at the bottom and a white open heart, friendly and bright, still flat and vector-like.

| image | model | refs | cost | decision |
|---|---|---|---|---|
| draft 1a | nano-banana-2.1 1K | refs/icon.png, refs/heart-dark.png | $0.053 | picked for a final: filled heart with a notch for the gap; cleanest favicon of the set |
| draft 1b | nano-banana-2.1 1K | refs/icon.png, refs/heart-dark.png | $0.050 | draft only |
| draft 2a | nano-banana-2.1 1K | refs/icon.png, refs/heart-dark.png | $0.052 | picked for a final: full-bleed amethyst tile with the heart cut out; loud in a dock and at 16 px |
| draft 2b | nano-banana-2.1 1K | refs/icon.png, refs/heart-dark.png | $0.045 | draft only |
| draft 3a | nano-banana-2.1 1K | refs/icon.png, refs/heart-dark.png | $0.058 | draft only |
| draft 3b | nano-banana-2.1 1K | refs/icon.png, refs/heart-dark.png | $0.057 | draft only |
| draft 4a | nano-banana-2.1 1K | refs/icon.png, refs/heart-dark.png | $0.043 | picked for a final: bright gradient tile with a white heart; friendliest app icon |
| draft 4b | nano-banana-2.1 1K | refs/icon.png, refs/heart-dark.png | $0.045 | draft only |
| final 1a-dark | Nano Banana Pro 4K | draft tile/1a, refs/icon.png, refs/heart-dark.png | $0.247 | shortlisted (Notched heart tile) |
| final 1a-light | Nano Banana Pro 4K + local fix | refs/inverted/tile-1a.png (local lightness inversion of the dark final) | $0.245 | shortlisted (Notched heart tile) |
| final 2a-dark | Nano Banana Pro 4K | draft tile/2a, refs/icon.png, refs/heart-dark.png | $0.248 | final, not shortlisted |
| final 2a-light | Nano Banana Pro 4K | refs/inverted/tile-2a.png (local lightness inversion of the dark final) | $0.490 | final, not shortlisted |
| final 4a-dark | Nano Banana Pro 4K | draft tile/4a, refs/icon.png, refs/heart-dark.png | $0.246 | final, not shortlisted |

## Shortlist

1. **Power heart** (`computer/1a`). The open gap becomes the line of a power symbol, so one glyph says 'a kinder computer'. One colour, one stroke weight, and it holds up at 16 px. Vector: Redraw on heart.svg's existing stroke and curl geometry, add the bar with the same round caps, then tune bar length and clearance so the gap stays open at 16 px. Outline the strokes for heart-glyph.svg.
2. **Block heart** (`block/1a`). The heart rebuilt from the wordmark's own cells and offset shadow, so mark and wordmark finally look like one family. Vector: No hand vector needed: write the heart as a cell grid (like icon.txt) and render it with brand.py's wordmark code (same CELL_W/H and shadow offset). A shadowless one-cell outline covers the glyph.
3. **Loop heart** (`heart/3b`). One continuous line with a single loop at the top; the warmest and most human of the set, and still clearly an open heart. Vector: One centreline path with even stroke and round caps, outlined. The loop's counter fills in below 32 px, so it needs a heavier small-size cut or the filled tile as the favicon.
4. **Notched heart tile** (`tile/1a`). A filled heart with a notch where the gap was; the boldest favicon and glyph here, and a solid sibling for any outline mark. Vector: Heart silhouette plus notch as one path, on icon.svg's existing tile and gradient. Check the notch survives at 16 px; widen it slightly for the glyph.
5. **Heart + lowercase lockup** (`lockup/1a`). The horizontal lockup the brand doesn't have yet, heart stroke matched to the letters. It raises the real question: keep the block MAITRI or move to lowercase. Vector: The lettering is a placeholder. Set 'maitri' in a real open-licence rounded sans, match the heart's stroke to the letter stems, and space it by hand. The heart is today's heart.svg.

## Cut 2: power heart and loop heart

Andrew liked shortlist picks 1 to 3 and asked for about five variations each of the power heart and the loop heart, each shown with the block MAITRI wordmark and a typeset lowercase lockup, at 16 and 32 px, and on daybreak. Sheets: `cut2/power.jpg`, `cut2/loop.jpg`, `cut2/favicons.jpg`.

- References: `refs/power-final.png` and `refs/loop-final.png`, the round 1 finals computer/1a-dark and heart/3b-dark scaled to 1536 px.
- Drafts: Nano Banana 2.1, 1K, three runs (a, b, c) per variation, 30 in all. Finals: Nano Banana Pro, 4K, with the picked draft as the reference.
- The first Pro pass also passed the round 1 final as a second reference; p2, p3 and p4 came back with ghosted copies of it, l3 lost its opening, l4 grew a stray tail and l5 wasn't bold. Those six were redone with the picked draft alone and a 'no ghosted shapes' line.
- Stroke weight barely moved in the drafts, so the finals for P1, P2 and L5 carry an explicit stroke ratio (6%, 13%, 12% of the heart's width).
- Everything on the sheets past the Pro final is local and deterministic: the mark's alpha is pulled from the final (grayscale, level 22% to 48%, small morphology open, trim), filled with exact #B08CFF or #644AC9, and set on flat #0F0A18 or #F5F5F5. So these daybreak versions are exact recolors, with no model in the loop.
- Block lockups use the real wordmark from tools/brand.py (amethyst and daybreak theme_wordmark), with the mark at 1.25x the wordmark height. Lowercase lockups are typeset in Nunito (SIL OFL, fetched as a file into scratch, nothing installed) at 600, 700 or 800 to match each mark's stroke. No model drew any lettering in cut 2.
- Transparent marks (`cut2/<id>-mark-<dark|light>.png`, 2304 px) and lockups (`cut2/<id>-<block|lower>-<dark|light>.png`) are on the branch for the vector pass.
- Cut 2 spend: $5.30 over 46 calls. Running total $17.46.

| variation | change | drafts | picked | final | cost |
|---|---|---|---|---|---|
| P1 Light | a noticeably thinner stroke, about two thirds of the reference weight (stroke width about 6% of the heart's overall width); a wider gap between the curl ends; a longer bar that reaches down to about the middle of the heart. | p1a, p1b, p1c | p1b | Pro 4K | $0.38 |
| P2 Bold | a much heavier stroke, about one and a half times the reference weight (stroke width about 13% of the heart's overall width); a short stubby bar; a narrow gap; built to read at 16 pixels. | p2a, p2b, p2c | p2c | Pro 4K, redone with draft only | $0.63 |
| P3 Soft | a softer, rounder heart with fuller lobes and a gently rounded bottom point instead of a sharp one; the curls are shorter and end higher; medium bar length. | p3a, p3b, p3c | p3a | Pro 4K, redone with draft only | $0.63 |
| P4 Rising bar | the bar starts above the top of the heart, rising clear of the lobes like a classic power symbol, and comes down into the gap to about one third of the heart's height; wide gap; medium stroke. | p4a, p4b, p4c | p4b | Pro 4K, redone with draft only | $0.63 |
| P5 Crisp | straighter sides and a crisper bottom point with only a small radius, the curl ends turned only slightly inward so the top reads as an open arc, a medium-length bar; precise and technical but still friendly. | p5a, p5b, p5c | p5c | Pro 4K | $0.38 |
| L1 Small loop | a tiny tight loop at the top centre, medium stroke, otherwise a clean symmetric heart. | l1a, l1b, l1c | l1b | Pro 4K | $0.38 |
| L2 Big loop | a large loop that drops well down into the middle of the heart, like a ribbon, medium stroke. | l2a, l2b, l2c | l2c | Pro 4K | $0.38 |
| L3 Open at the bottom | the line does not close: it starts and ends near the bottom point, leaving a small gap just left of the point, so the heart is drawn in one stroke that stays open; small loop at the top. | l3a, l3b, l3c | l3a | Pro 4K, redone with draft only | $0.63 |
| L4 Signature | the line starts inside the loop and ends with a free tail on the right lobe that does not rejoin, like a hand-signed heart; slightly calligraphic rhythm but even stroke. | l4a, l4b, l4c | l4c | Pro 4K, redone with draft only | $0.63 |
| L5 Bold | a much heavier stroke (stroke width about 12% of the heart's overall width) with the loop sized so its inner hole stays clearly open; built to read at 16 and 32 pixels; softly rounded bottom point. | l5a, l5b, l5c | l5b | Pro 4K, redone with draft only | $0.63 |
