# maitri wallpaper candidates: provenance log

Generated 2026-10-17 for review on k7lab/maitrios#23. AI-assisted images: Google Gemini API, paid tier (Nano Banana 2.1 `gemini-nano-banana-2.1` for drafts, Nano Banana Pro `gemini-3-pro-image` for finals). Google claims no ownership of output. The images carry Google's invisible SynthID watermark.

## Human steps (all images)

1. **Briefs.** Per-theme style briefs written for #21 from each theme's `colors.toml` and the existing maitri backgrounds, then signed off by Andrew.
2. **Prompts.** A shared style prefix plus a theme mood and one composition per family (landscape, flow, form, light, particles), written by hand from the briefs and tied to each theme's `background` and `accent` hex values.
3. **Round 1 (rejected).** 60 drafts and 30 Pro finals of soft light washes. On review Andrew asked for more ambition: real structure and depth, so the wash/texture family was dropped and the prompts were rewritten. The round-1 Pro finals were rendered at 4K and also showed tile seams (the 4K output is stitched from ~1K tiles with mismatched tone), so finals moved to 2K plus a local upscale.
4. **Round 2 drafts.** 60 drafts (2 per prompt). For each prompt the better of the two was picked by eye for composition, a calm top strip and centre, and fit with the brief.
5. **Reference boards.** 3 picked drafts per theme became that theme's style board. Each final got its own draft first (composition) plus two board drafts.
6. **Finals.** 2 Pro renders per pick at 2K 16:9. The better render was chosen after a quick post-process and the scripted checks; renders with letterbox bands, inset frames or open flames were rejected (spark 5 and garnet 5 were swapped to their sibling render for a band across the top).
7. **Post-processing** (deterministic, scripted, parameters below):
   - centre crop from 16:9 to 16:10;
   - tone: lightness scaled toward the theme background so the 97th percentile sits at or below L* 42 and the mean at or below L* 16 (daybreak mirrored: 3rd percentile at or above L* 62, mean at or above L* 89), with a soft shoulder toward the accent;
   - safe-zone dim (dark themes only): a soft elliptical mask centred at (50%, 45%) eases lightness up to 45% toward the background under the launcher area, driven by a smoothed base layer so it leaves no contour;
   - palette lock in OKLab: hue and chroma pulled toward a ramp built from the theme's `colors.toml` at matching lightness (60% blend for dark themes, 40% for daybreak), so gradients keep their shape;
   - Real-ESRGAN x4plus (BSD-3, ncnn-vulkan build) upscale in 384 px tiles with a 48 px feathered overlap (its own tiling left faint seams on flat skies), then Lanczos to 5120x3200;
   - monochrome grain (sigma 1.2% dark, 0.8% daybreak, 0.6 px blur), JPEG q92 4:4:4, no EXIF/XMP/ICC metadata.
8. **Checks.** Mean and safe-zone lightness, centre detail, bright pixels, accent presence (table below). Andrew makes the final call.

Spend: $23.38 of the $50 cap (drafts $7.23, finals $16.11, smoke tests $0.04).

## Shared prompt prefix

Dark themes:

> Cinematic desktop wallpaper with real depth and structure: a clear subject with form, layered light and a sense of scale, rendered like a high-end photograph or 3D still, soft and atmospheric rather than busy. The subject and the brightest light sit in the lower third or one lower corner; the top strip and the middle of the frame stay calm, dark and uncluttered, a resting area where icons, a launcher and text sit on top. Dark overall, with the accent color as the light that shapes the subject. Fine film grain. No text, no logos, no icons, no UI elements, no people, no animals, no buildings, no vehicles, no stars, no moon, no frames or borders. Dominant tone {background}, light in {accent}.

daybreak:

> Cinematic desktop wallpaper with real depth and structure: a clear subject with form, layered soft light and a sense of scale, rendered like a high-end photograph or 3D still, airy rather than busy. The subject sits in the lower third or one lower corner; the top strip and the middle of the frame stay calm, pale and uncluttered, a resting area where icons, a launcher and dark text sit on top. Light overall: soft paper white, nothing darker than a soft mid-tone anywhere, the accent color as pale washes and soft shadows. Very fine film grain. No text, no logos, no icons, no UI elements, no people, no animals, no buildings, no sun, no frames or borders. Dominant tone {background}, a pale wash of {accent}.

## Per image

### amethyst (background `#0F0A18`, accent `#B08CFF`)

**amethyst/1.jpg** (landscape)

- Prompt: theme mood + composition: "Layer upon layer of distant mountain ridges in deep violet silhouette filling only the bottom quarter of the frame, receding into haze, with a lavender afterglow along the farthest ridge. A vast sense of scale; the sky above is calm, nearly black violet."
- Draft picked: `1-landscape-b` from 2 drafts. References for the final: `1-landscape-b`, `2-flow-a`, `5-particles-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `1-landscape-a` picked from 2
- Post: tone gain 0.732, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

**amethyst/2.jpg** (flow)

- Prompt: theme mood + composition: "A single enormous fold of dark satin sweeping through the lower third from the left edge, its crest catching a thin line of lavender light, the rest falling away into shadow. Smooth, sculptural, slow."
- Draft picked: `2-flow-a` from 2 drafts. References for the final: `2-flow-a`, `1-landscape-b`, `5-particles-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `2-flow-b` picked from 2
- Post: tone gain 1.0, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: busy centre, hot spot

**amethyst/3.jpg** (form)

- Prompt: theme mood + composition: "A large amethyst geode in the lower right corner, close up, its crystal interior glowing softly lavender from within, shallow depth of field so most of it melts into dark bokeh; the rest of the frame is empty violet-black."
- Draft picked: `3-form-a` from 2 drafts. References for the final: `3-form-a`, `1-landscape-b`, `2-flow-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `3-form-a` picked from 2
- Post: tone gain 0.691, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: busy centre, hot spot

**amethyst/4.jpg** (light)

- Prompt: theme mood + composition: "Several thin translucent curved glass planes standing in depth across the lower third, each catching lavender edge light, receding toward a soft vanishing point. Quiet, architectural, abstract."
- Draft picked: `4-light-b` from 2 drafts. References for the final: `4-light-b`, `1-landscape-b`, `2-flow-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `4-light-b` picked from 2
- Post: tone gain 1.0, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: busy centre

**amethyst/5.jpg** (particles)

- Prompt: theme mood + composition: "A vast flowing surface made of millions of tiny soft dots, like a slow wave of fine particles rolling across the lower third and receding toward a distant horizon, lit lavender along the crest and fading into violet-black; the top half of the frame is empty dark."
- Draft picked: `5-particles-b` from 2 drafts. References for the final: `5-particles-b`, `1-landscape-b`, `2-flow-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `5-particles-a` picked from 2
- Post: tone gain 0.568, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: busy centre

### spark (background `#0B0F17`, accent `#82AAFF`)

**spark/1.jpg** (landscape)

- Prompt: theme mood + composition: "The curved horizon of an enormous dark sphere seen from high above, filling the bottom fifth of the frame, with a thin periwinkle atmosphere glowing along its edge and a faint second layer of haze above it. Vast scale; everything above the arc is calm blue-black."
- Draft picked: `1-landscape-b` from 2 drafts. References for the final: `1-landscape-b`, `2-flow-a`, `5-particles-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `1-landscape-a` picked from 2
- Post: tone gain 0.627, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

**spark/2.jpg** (flow)

- Prompt: theme mood + composition: "A long-exposure ribbon of periwinkle light sweeping in one smooth curve through the lower third, with layered fainter echoes trailing behind it in depth, as if something fast just passed by."
- Draft picked: `2-flow-a` from 2 drafts. References for the final: `2-flow-a`, `1-landscape-b`, `5-particles-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `2-flow-a` picked from 2
- Post: tone gain 0.526, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: busy centre

**spark/3.jpg** (form)

- Prompt: theme mood + composition: "A dark, smooth, glassy sculptural form rising from the lower left corner, its curved edges traced by a crisp periwinkle rim light, the rest of it lost in shadow; shallow depth of field."
- Draft picked: `3-form-b` from 2 drafts. References for the final: `3-form-b`, `1-landscape-b`, `2-flow-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `3-form-b` picked from 2
- Post: tone gain 0.996, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: busy centre, hot spot

**spark/4.jpg** (light)

- Prompt: theme mood + composition: "Low, layered sheets of cold blue light hanging over a dark, mirror-flat plain in the lower third, reflected faintly below it, receding into deep distance."
- Draft picked: `4-light-b` from 2 drafts. References for the final: `4-light-b`, `1-landscape-b`, `2-flow-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `4-light-a` picked from 2
- Post: tone gain 0.804, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

**spark/5.jpg** (particles)

- Prompt: theme mood + composition: "A stream of tiny cold sparks flowing in a wide curving band across the lower third, dense and bright at the near end in the lower right and thinning into the distance, a few sparks drifting off it; the rest of the frame is calm blue-black."
- Draft picked: `5-particles-b` from 2 drafts. References for the final: `5-particles-b`, `1-landscape-b`, `2-flow-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `5-particles-a` picked from 2
- Post: tone gain 0.52, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

### harbor (background `#08120F`, accent `#4FE0C4`)

**harbor/1.jpg** (landscape)

- Prompt: theme mood + composition: "A still night lake seen from low on the shore: a line of low dark hills on the far side sits on the horizon in the lower third, a band of teal mist hangs on the water in front of them, and a few soft points of teal light reflect as long streaks in the mirror-calm water. Wide and deep."
- Draft picked: `1-landscape-b` from 2 drafts. References for the final: `1-landscape-b`, `2-flow-a`, `3-form-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `1-landscape-a` picked from 2
- Post: tone gain 0.725, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: busy centre, hot spot

**harbor/2.jpg** (flow)

- Prompt: theme mood + composition: "Gentle waves rolling onto a dark shore at the bottom of the frame, each breaking edge glowing with bioluminescent teal foam, long exposure so the water turns silky; the sky above is empty green-black."
- Draft picked: `2-flow-a` from 2 drafts. References for the final: `2-flow-a`, `1-landscape-b`, `3-form-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `2-flow-b` picked from 2
- Post: tone gain 0.728, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

**harbor/3.jpg** (form)

- Prompt: theme mood + composition: "Concentric ripples spreading across dark still water from a single drop in the lower third, seen at a low angle, each ring catching a thin line of teal light; shallow depth of field, the far water fading into mist."
- Draft picked: `3-form-a` from 2 drafts. References for the final: `3-form-a`, `1-landscape-b`, `2-flow-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `3-form-a` picked from 2
- Post: tone gain 0.491, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: busy centre

**harbor/4.jpg** (light)

- Prompt: theme mood + composition: "Layers of fog banks over dark water receding into the distance across the lower third, each layer lit faintly teal from within, giving a deep sense of scale."
- Draft picked: `4-light-b` from 2 drafts. References for the final: `4-light-b`, `1-landscape-b`, `2-flow-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `4-light-b` picked from 2
- Post: tone gain 0.743, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: busy centre

**harbor/5.jpg** (particles)

- Prompt: theme mood + composition: "A drifting cloud of tiny bioluminescent teal particles swirling just above dark still water in the lower third, mirrored in the water, thinning out into the darkness above."
- Draft picked: `5-particles-b` from 2 drafts. References for the final: `5-particles-b`, `1-landscape-b`, `2-flow-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `5-particles-a` picked from 2
- Post: tone gain 1.0, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

### ember (background `#140E06`, accent `#FF9B54`)

**ember/1.jpg** (landscape)

- Prompt: theme mood + composition: "A vast dark landscape of rolling hills under a night sky, with the amber glow of a fire just beyond the horizon lighting the edges of the nearest ridges in the bottom quarter. Huge scale, calm dark sky."
- Draft picked: `1-landscape-b` from 2 drafts. References for the final: `1-landscape-b`, `4-light-b`, `5-particles-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `1-landscape-b` picked from 2
- Post: tone gain 1.0, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: accent

**ember/2.jpg** (flow)

- Prompt: theme mood + composition: "Slow ribbons of smoke rising from the bottom edge, lit warm amber from below, folding and curling in layers, fading out completely before the middle of the frame."
- Draft picked: `2-flow-b` from 2 drafts. References for the final: `2-flow-b`, `1-landscape-b`, `4-light-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `2-flow-b` picked from 2
- Post: tone gain 0.931, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: busy centre, accent

**ember/3.jpg** (form)

- Prompt: theme mood + composition: "A bed of glowing coals close up in the lower right corner, cracked and textured, amber light inside the cracks, shallow depth of field so it melts into warm dark bokeh; a few embers drift up and fade."
- Draft picked: `3-form-a` from 2 drafts. References for the final: `3-form-a`, `1-landscape-b`, `4-light-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `3-form-a` picked from 2
- Post: tone gain 0.756, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

**ember/4.jpg** (light)

- Prompt: theme mood + composition: "A dark, cooled lava plain stretching to the horizon across the lower third, with a few thin amber fissures glowing in lines that recede into the distance. An enormous sense of scale."
- Draft picked: `4-light-b` from 2 drafts. References for the final: `4-light-b`, `1-landscape-b`, `5-particles-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `4-light-b` picked from 2
- Post: tone gain 1.0, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: accent

**ember/5.jpg** (particles)

- Prompt: theme mood + composition: "Thousands of tiny embers rising in a slow, wide plume from the bottom edge, near ones large and soft out of focus, far ones tiny and sharp, all fading out before the middle."
- Draft picked: `5-particles-b` from 2 drafts. References for the final: `5-particles-b`, `1-landscape-b`, `4-light-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `5-particles-b` picked from 2
- Post: tone gain 1.0, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

### garnet (background `#140A0B`, accent `#FF6E84`)

**garnet/1.jpg** (landscape)

- Prompt: theme mood + composition: "Rolling dunes of deep wine-colored sand in the bottom quarter of the frame under a dark sky, their crests rim-lit by a low rose-red light, long soft shadows. A vast, quiet scale."
- Draft picked: `1-landscape-b` from 2 drafts. References for the final: `1-landscape-b`, `2-flow-a`, `3-form-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `1-landscape-b` picked from 2
- Post: tone gain 1.0, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

**garnet/2.jpg** (flow)

- Prompt: theme mood + composition: "Heavy folds of dark velvet flowing across the bottom of the frame, sculptural and slow, their ridges catching a soft rose-red light, the hollows falling into deep wine-black."
- Draft picked: `2-flow-a` from 2 drafts. References for the final: `2-flow-a`, `3-form-a`, `5-particles-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `2-flow-a` picked from 2
- Post: tone gain 0.903, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

**garnet/3.jpg** (form)

- Prompt: theme mood + composition: "A cut garnet gemstone in the lower right corner, extremely close up, its facets glowing rose-red from within, very shallow depth of field so most of it dissolves into soft rose bokeh against wine-black."
- Draft picked: `3-form-a` from 2 drafts. References for the final: `3-form-a`, `2-flow-a`, `5-particles-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `3-form-a` picked from 2
- Post: tone gain 0.759, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

**garnet/4.jpg** (light)

- Prompt: theme mood + composition: "Layered translucent curved panes like thin sheets of rose-tinted glass, standing in depth across the lower third and catching rose-red edge light, receding into dark."
- Draft picked: `4-light-b` from 2 drafts. References for the final: `4-light-b`, `2-flow-a`, `3-form-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `4-light-b` picked from 2
- Post: tone gain 0.677, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

**garnet/5.jpg** (particles)

- Prompt: theme mood + composition: "A slow swirl of tiny rose-red particles like fine glitter suspended in dark liquid, gathered in the lower right and drifting out into wine-black, near ones soft bokeh, far ones pinpoints."
- Draft picked: `5-particles-b` from 2 drafts. References for the final: `5-particles-b`, `2-flow-a`, `3-form-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `5-particles-a` picked from 2
- Post: tone gain 0.792, safe-zone dim 0.45, palette lock 0.6, Real-ESRGAN yes, grain 0.012
- Checks: pass

### daybreak (background `#F5F5F5`, accent `#644AC9`)

**daybreak/1.jpg** (landscape)

- Prompt: theme mood + composition: "Soft rolling hills in layered pale violet haze along the bottom quarter of the frame at first light, each ridge lighter than the one in front, a hint of warm peach low on the far horizon, the rest airy paper white."
- Draft picked: `1-landscape-a` from 2 drafts. References for the final: `1-landscape-a`, `2-flow-b`, `3-form-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `1-landscape-a` picked from 2
- Post: tone gain 1.0, safe-zone dim 0, palette lock 0.4, Real-ESRGAN yes, grain 0.008
- Checks: pass

**daybreak/2.jpg** (flow)

- Prompt: theme mood + composition: "A large sheet of white silk folding in a slow, sculptural curve across the lower third, its shadows tinted pale violet and its lit edges warm peach. Clean and airy."
- Draft picked: `2-flow-b` from 2 drafts. References for the final: `2-flow-b`, `1-landscape-a`, `3-form-a`
- Final: `gemini-3-pro-image` at 2K 16:9, render `2-flow-b` picked from 2
- Post: tone gain 1.0, safe-zone dim 0, palette lock 0.4, Real-ESRGAN yes, grain 0.008
- Checks: pass

**daybreak/3.jpg** (form)

- Prompt: theme mood + composition: "A few smooth white porcelain pebbles in the lower right corner, softly lit from the top right, casting long pale violet shadows across a white surface; shallow depth of field."
- Draft picked: `3-form-a` from 2 drafts. References for the final: `3-form-a`, `1-landscape-a`, `2-flow-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `3-form-a` picked from 2
- Post: tone gain 0.963, safe-zone dim 0, palette lock 0.4, Real-ESRGAN yes, grain 0.008
- Checks: busy centre, hot spot

**daybreak/4.jpg** (light)

- Prompt: theme mood + composition: "Early light falling across a plain white wall, making a few soft-edged pale violet and peach light shapes in the lower right; no window frame visible, the rest of the wall plain and very low contrast."
- Draft picked: `4-light-b` from 2 drafts. References for the final: `4-light-b`, `1-landscape-a`, `2-flow-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `4-light-b` picked from 2
- Post: tone gain 0.949, safe-zone dim 0, palette lock 0.4, Real-ESRGAN yes, grain 0.008
- Checks: pass

**daybreak/5.jpg** (particles)

- Prompt: theme mood + composition: "A faint wave of tiny pale violet dots flowing across the lower third like a sheet of fine particles, receding into the distance and fading into paper white."
- Draft picked: `5-particles-b` from 2 drafts. References for the final: `5-particles-b`, `1-landscape-a`, `2-flow-b`
- Final: `gemini-3-pro-image` at 2K 16:9, render `5-particles-b` picked from 2
- Post: tone gain 1.0, safe-zone dim 0, palette lock 0.4, Real-ESRGAN yes, grain 0.008
- Checks: pass

## Luminance and checks

| theme | # | subject | mean L* | safe-zone L* | centre L* | bright px % | accent px % | checks |
|---|---|---|---|---|---|---|---|---|
| amethyst | 1 | landscape | 10.6 | 12.1 | 10.0 | 1.12 | 100.0 | pass |
| amethyst | 2 | flow | 7.7 | 8.8 | 11.4 | 0.0 | 97.2 | busy centre, hot spot |
| amethyst | 3 | form | 8.6 | 9.5 | 8.5 | 0.14 | 83.7 | busy centre, hot spot |
| amethyst | 4 | light | 8.9 | 10.2 | 9.3 | 0.34 | 99.9 | busy centre |
| amethyst | 5 | particles | 9.3 | 9.1 | 7.7 | 0.39 | 99.8 | busy centre |
| spark | 1 | landscape | 9.9 | 11.7 | 11.7 | 0.26 | 91.7 | pass |
| spark | 2 | flow | 10.4 | 10.9 | 10.6 | 0.0 | 98.6 | busy centre |
| spark | 3 | form | 11.7 | 10.7 | 10.4 | 0.84 | 98.8 | busy centre, hot spot |
| spark | 4 | light | 9.5 | 11.4 | 8.2 | 0.73 | 96.8 | pass |
| spark | 5 | particles | 9.3 | 9.7 | 8.6 | 0.18 | 96.1 | pass |
| harbor | 1 | landscape | 12.2 | 13.8 | 12.9 | 0.09 | 45.6 | busy centre, hot spot |
| harbor | 2 | flow | 13.6 | 13.0 | 9.6 | 1.49 | 52.1 | pass |
| harbor | 3 | form | 12.2 | 12.1 | 14.3 | 0.0 | 68.5 | busy centre |
| harbor | 4 | light | 10.2 | 11.5 | 11.0 | 2.01 | 64.3 | busy centre |
| harbor | 5 | particles | 11.3 | 12.3 | 9.6 | 0.29 | 83.3 | pass |
| ember | 1 | landscape | 9.8 | 10.7 | 8.0 | 0.47 | 27.1 | accent |
| ember | 2 | flow | 9.1 | 8.1 | 8.8 | 1.02 | 28.5 | busy centre, accent |
| ember | 3 | form | 10.5 | 10.0 | 8.9 | 0.96 | 37.8 | pass |
| ember | 4 | light | 10.4 | 11.7 | 13.7 | 0.0 | 35.8 | accent |
| ember | 5 | particles | 9.9 | 11.1 | 10.7 | 0.39 | 37.2 | pass |
| garnet | 1 | landscape | 8.5 | 7.5 | 6.4 | 1.41 | 98.6 | pass |
| garnet | 2 | flow | 7.3 | 5.7 | 5.3 | 2.03 | 85.1 | pass |
| garnet | 3 | form | 9.4 | 9.8 | 8.7 | 0.74 | 99.8 | pass |
| garnet | 4 | light | 9.4 | 8.1 | 6.4 | 0.93 | 85.4 | pass |
| garnet | 5 | particles | 9.4 | 9.0 | 6.3 | 0.29 | 99.5 | pass |
| daybreak | 1 | landscape | 91.2 | 92.6 | 94.7 | 0.0 | 25.0 | pass |
| daybreak | 2 | flow | 90.0 | 91.3 | 93.5 | 0.59 | 31.3 | pass |
| daybreak | 3 | form | 89.0 | 90.1 | 93.9 | 1.17 | 64.3 | busy centre, hot spot |
| daybreak | 4 | light | 88.8 | 89.7 | 90.9 | 0.0 | 63.3 | pass |
| daybreak | 5 | particles | 96.5 | 96.6 | 96.6 | 0.0 | 16.1 | pass |

## Update 2026-10-17: picks and ember re-tone

Andrew approved all 30 round-2 candidates. ember's accent moved to `#FF9B54` in the palette update (#56), and the first post-process read brown-gold, so only ember's post-processing was re-run. There were no new renders and no extra spend. ember overrides:

- highlight cap raised from L* 42 to L* 68 (shoulder knee L* 70), so the glow, coals, lava cracks and sparks keep the accent's lightness; the mean is still capped at L* 16;
- the palette ramp's mid stop is the accent darkened 55% toward the background instead of `muted` (`#4E3A1C`, a brown);
- palette lock 0.6 (unchanged), plus a 1.3× OKLab chroma lift;
- everything else as above (crop, safe-zone dim 0.45, Real-ESRGAN with feathered 384 px tiles, grain 1.2%, JPEG q92 4:4:4, no metadata).

New ember checks:

| theme | # | subject | mean L* | safe-zone L* | centre L* | bright px % | accent px % | checks |
|---|---|---|---|---|---|---|---|---|
| ember | 1 | landscape | 9.7 | 10.6 | 8.0 | 0.49 | 33.6 | accent |
| ember | 2 | flow | 9.4 | 8.2 | 8.9 | 1.53 | 66.4 | busy centre |
| ember | 3 | form | 12.4 | 11.7 | 10.1 | 3.01 | 51.7 | busy centre, hot spot |
| ember | 4 | light | 10.3 | 11.5 | 13.6 | 0.0 | 51.2 | pass |
| ember | 5 | particles | 10.0 | 11.2 | 10.7 | 0.41 | 47.3 | pass |
