# Low-Poly Garden Vegetation Prompts for Nano Banana → Meshy Image-to-3D

Purpose: generate clean **2D reference images first**, then use those images in **Meshy Image-to-3D**. These prompts are **not optimized for Meshy Text-to-3D**. They are image prompts designed to produce clear, centered, simple silhouettes that convert better into low-poly SketchUp vegetation components.

**Height convention:** the heights below are **intended SketchUp design-component heights**, not botanical maximum mature heights. For clipped hedges, front-of-border shrubs, groundcovers, and repeated drifts, the useful model height is deliberately lower than the species could theoretically reach. Use the default height for first placement, then scale individual components in SketchUp when the planting role changes.

## Image-first rules

Use these prompts one model at a time.

**Common image style to keep in every prompt:**

```text
clean low-poly 3D game asset render, single object, centered, full object visible, orthographic three-quarter view, plain light gray background, flat matte colors, faceted polygon shapes, no labels, no text, no pot, no soil scene
```

**Why this matters:** Meshy Image-to-3D usually works better from a clear, isolated, well-lit object image than from a prompt trying to describe the final mesh directly. For vegetation, avoid fine botanical detail. Use fewer, larger, readable shapes.

**Avoid in Nano Banana image prompts:**

```text
realistic plant photo, dense tiny leaves, complex foliage, tangled branches, transparent leaves, full garden scene, multiple different plants, asset sheet, labels, text, pot, soil bed, dramatic lighting
```

---

## 1. Clipped Rectangular Hedge Block

**Short description:** Formal clipped hedge segment; simple rectangular green mass.

**Approximate SketchUp height:** 0.5–1.0 m for the clipped low hedge role; use ~0.7 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single clipped rectangular hedge block. The hedge is a compact green cuboid with straight vertical sides, a flat clipped top, and a slightly uneven faceted foliage surface. Use dark green and medium green matte polygon patches, simple chunky geometry, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Taxus × media 'Groenland'
- Carpinus betulus, when clipped
- Euonymus fortunei, when clipped
- Lonicera nitida

**Use / generation notes:**

Best for formal edges, low garden partitions, and repeated hedge runs. In SketchUp, stretch or duplicate this component instead of creating many hedge lengths. Keep it blocky; do not ask for individual leaves.

---

## 2. Tall Clipped Hedge Screen

**Short description:** Tall vertical hedge wall for privacy and enclosure.

**Approximate SketchUp height:** 1.6–2.5 m for maintained privacy / boundary hedge use; use ~2.0 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single tall clipped hedge screen. It is a vertical rectangular wall of dense green foliage, narrow in depth, with a flat top and crisp formal sides. The surface is made from large faceted polygon foliage patches in dark evergreen green and medium green. Centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no trunk, no pot, no soil scene.
```

**Represents:**

- Carpinus betulus
- Taxus × media 'Groenland'
- Tall clipped Prunus laurocerasus
- Tall clipped Prunus lusitanica

**Use / generation notes:**

Use where the design needs height, screening, and enclosure. This should read as a green architectural wall, not as a natural shrub.

---

## 3. Dense Broadleaf Evergreen Shrub Mass

**Short description:** Heavy evergreen backdrop shrub, laurel-like mass.

**Approximate SketchUp height:** 1.4–2.3 m for dense evergreen backdrop massing; use ~1.8 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single dense broadleaf evergreen shrub. The shrub is a large rounded oval mound with a heavy full silhouette, made from large simple angular leaf plates and chunky green foliage clumps. Use dark glossy green and medium green matte colors, faceted polygon shapes, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no flowers, no pot, no soil scene.
```

**Represents:**

- Prunus laurocerasus
- Prunus lusitanica
- Osmanthus × burkwoodii
- Euonymus japonicus

**Use / generation notes:**

Use for dense evergreen backdrop and boundary mass. This should look more solid and heavy than a loose deciduous shrub. Avoid tiny leaves; ask for large angular leaf plates.

---

## 4. Rounded Evergreen Shrub Mound

**Short description:** Medium evergreen dome, softer and smaller than the laurel mass.

**Approximate SketchUp height:** 0.7–1.3 m for medium evergreen filler; use ~0.9 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single rounded evergreen shrub mound. The plant is a compact dome with irregular faceted foliage, a few large angular leaf shapes visible on the surface, and a soft rounded outline. Use dark green, yellow-green, and medium green matte colors, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no flowers, no pot, no soil scene.
```

**Represents:**

- Mahonia
- Euonymus fortunei, shrub form
- Euonymus japonicus, smaller form
- Osmanthus × burkwoodii, smaller form

**Use / generation notes:**

Use as medium evergreen filler. For Mahonia-like placements, use a slightly spikier material/shape variant, but the same archetype is enough for conceptual modeling.

---

## 5. Low Conifer Mound

**Short description:** Squat spreading pine-like evergreen mound.

**Approximate SketchUp height:** 0.5–1.0 m for a low dwarf-conifer mound; use ~0.7 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single low conifer mound. The plant is squat and spreading, with layered rounded pads like a dwarf pine, made from chunky faceted needle-like masses rather than tiny needles. Use dark green and blue-green matte colors, compact ground-hugging silhouette, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no cones, no pot, no soil scene.
```

**Represents:**

- Pinus mugo

**Use / generation notes:**

Use for low evergreen winter structure and textural contrast. It should not look like a small Christmas tree or upright conifer.

---

## 6. Upright Juniper / Conifer Accent

**Short description:** Narrow blue-green vertical conifer plume.

**Approximate SketchUp height:** 1.5–2.5 m for an upright accent conifer; use ~2.0 m as the default component height. Use 2.5–3.0 m only if it is meant to read as a screening element rather than an accent.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single upright juniper conifer. The shape is narrow, vertical, slightly tapered, and plume-like, with an irregular natural outline. The foliage is represented by large faceted blue-green and dark green polygon masses, not tiny needles. Centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Juniperus chinensis

**Use / generation notes:**

Use as vertical punctuation in mixed planting. Scale vertically in SketchUp for different maturity sizes.

---

## 7. Loose Deciduous Boundary Shrub

**Short description:** Informal shrub body with open, natural massing.

**Approximate SketchUp height:** 1.4–2.2 m for informal boundary shrub massing; use ~1.7 m as the default component height. Use a separate larger specimen scale only for Cornus or Hamamelis if they are meant to read as small trees.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single loose deciduous boundary shrub. The shrub has an irregular rounded silhouette, visible simple brown branching stems, and medium green polygon leaf clumps arranged with a few open gaps. It should feel natural and informal, not clipped. Centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no flowers, no pot, no soil scene.
```

**Represents:**

- Cornus mas
- Physocarpus
- Hardy Viburnum
- Viburnum carlesii, non-flowering phase
- Philadelphus, non-flowering phase
- Weigela florida, non-flowering phase
- Hamamelis × intermedia

**Use / generation notes:**

This is the main informal screening shrub. Create material variants for green, burgundy, or autumn foliage if needed. For Hamamelis or Cornus winter interest, use a leafless branch variant.

---

## 8. Arching Flowering Shrub

**Short description:** Fountain-shaped shrub with arching flowering branches.

**Approximate SketchUp height:** 0.9–1.6 m for arching ornamental shrub use; use ~1.2 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single arching flowering shrub. The plant forms a soft fountain mound with several curved brown branch arcs, simple green polygon leaf clusters, and small white flower dots along the outer branches. Keep the silhouette airy and graceful, with large simple shapes. Centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Spiraea × cinerea 'Grefsheim'
- Deutzia gracilis
- Kerria japonica
- Philadelphus
- Weigela florida
- Ribes, informal flowering form

**Use / generation notes:**

Use for ornamental shrubs that should read as softer and more arching than dense shrubs. Change flower color in SketchUp: white for Spiraea/Deutzia/Philadelphus, yellow for Kerria, pink for Weigela.

---

## 9. Large Rounded Flowering Shrub

**Short description:** Hydrangea/viburnum-like dome with large flower heads.

**Approximate SketchUp height:** 1.2–2.0 m for hydrangea/viburnum-like flowering mass; use ~1.5 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single large rounded flowering shrub. The shrub is a full green dome with broad faceted leaves and several large simple cream-white flower clusters sitting on the top and outer sides. The flower clusters are rounded cone-like low-poly shapes, not tiny petals. Centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Hydrangea paniculata
- Viburnum carlesii
- Hardy Viburnum, flowering phase

**Use / generation notes:**

Use where the garden needs visible flower mass and focal volume. Keep flower heads large and geometric; do not ask for detailed petals.

---

## 10. Low Front Flowering Shrub Mound

**Short description:** Small front-of-border shrub with simple flowers.

**Approximate SketchUp height:** 0.5–1.0 m for front-of-mass shrub use; use ~0.7 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single low flowering shrub mound. The plant is compact, low, and rounded, with bright green faceted foliage and scattered simple red, pink, or white flower dots. It has a wide low silhouette suitable for the front of a border. Centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Chaenomeles japonica
- Aronia
- Ribes
- Small Spiraea / Deutzia placements

**Use / generation notes:**

Use in front of larger shrub masses. This should be clearly smaller than Models 7–9. If the result becomes too blobby, remove flowers and add them later as small SketchUp components or materials.

---

## 11. Climbing Foliage / Flowering Vine Panel

**Short description:** Thin foliage sheet for wall or fence coverage.

**Approximate SketchUp height:** match the support: usually 1.5–2.0 m for a fence/wall panel; use ~1.8 m as the default panel height. Use 2.5 m+ only for pergolas or taller structures.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single thin climbing vine foliage panel. The object is a flat vertical irregular rectangle made of overlapping large polygon ivy-like leaves, like a lightweight foliage sheet for placing on a fence or wall. Add a few simple purple or yellow flower dots only on some leaves. Centered full object, orthographic three-quarter view, plain light gray background, no fence, no wall, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Hedera helix
- Parthenocissus
- Clematis viticella
- Jasminum nudiflorum

**Use / generation notes:**

Use as a surface-attached component. For ivy and Parthenocissus, use no flowers. For Clematis, use purple dots. For Jasminum nudiflorum, use yellow dots and a sparser version.

---

## 12. Bamboo Screen Clump

**Short description:** Vertical bamboo stems with sparse leaves.

**Approximate SketchUp height:** 2.5–3.5 m for a garden screening clump; use ~3.0 m as the default component height. Keep taller versions rare unless the bamboo is a dominant boundary screen.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single bamboo screen clump. The plant has several slightly thick vertical green canes rising from one base, with sparse narrow lance-shaped leaves near the upper stems. The canes are simple cylinders and the leaves are flat polygon shapes. Use yellow-green and medium green matte colors, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Phyllostachys bissetii

**Use / generation notes:**

Thin stems can fail in Image-to-3D, so the prompt asks for slightly thick canes. Duplicate several clumps in SketchUp to make a screen.

---

## 13. Low Groundcover Carpet Patch

**Short description:** Very low spreading oval patch.

**Approximate SketchUp height:** 0.08–0.20 m for foliage carpet; use ~0.12 m as the default component height. Flowering stems can be scaled up to ~0.30–0.35 m if needed.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single low groundcover carpet patch. The object is a very shallow oval mat with an uneven organic edge, made from many broad simple polygon leaves lying close to the ground. Use medium green and yellow-green matte colors, flat faceted shapes, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no tall stems, no pot, no soil scene.
```

**Represents:**

- Geranium macrorrhizum
- Waldsteinia ternata
- Vinca minor

**Use / generation notes:**

Use as a repeated low carpet. Keep it almost flat. In SketchUp, scale and overlap copies to create drifts.

---

## 14. Broad-Leaf Shade Clump

**Short description:** Hosta-like low mound of large leaves.

**Approximate SketchUp height:** 0.25–0.55 m for broad-leaf shade foliage; use ~0.35–0.40 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single broad-leaf shade plant clump. The plant is a low mound of large oval and heart-shaped leaves radiating from the base, with overlapping simple faceted leaf surfaces. Use blue-green, lime green, and medium green matte colors. Centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no flowers, no pot, no soil scene.
```

**Represents:**

- Hosta
- Brunnera macrophylla
- Heuchera
- Helleborus × hybridus
- Tiarella, foliage form

**Use / generation notes:**

Use wherever the scene needs broad shade foliage. Change color for species feel: blue-green for Hosta, silver-green for Brunnera, bronze/purple for Heuchera, dark green for Helleborus.

---

## 15. Fern Texture Clump

**Short description:** Simplified fern with large readable fronds.

**Approximate SketchUp height:** 0.45–1.0 m for fern texture; use ~0.65 m as the default component height. Use the upper end for Matteuccia-like upright ferns.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single fern clump. The plant has several large arching feather-shaped fronds radiating from a central base. Each frond is simplified into broad angular leaflet shapes, not tiny details. Use fresh green and dark green matte colors, airy layered silhouette, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Dryopteris
- Matteuccia

**Use / generation notes:**

Use for fine shade texture. Matteuccia can be taller and more upright; Dryopteris can be lower and more arching. Avoid tiny feather detail because it often turns into noisy geometry.

---

## 16. Low Cascading Grass Drift

**Short description:** Soft low fountain grass, Hakonechloa-like.

**Approximate SketchUp height:** 0.25–0.45 m for Hakonechloa-like low grass; use ~0.35 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single low cascading ornamental grass clump. The plant has long broad ribbon-like blade leaves arching outward and downward from the center, forming a soft fountain shape. Use lime green and yellow-green matte colors, simple faceted polygon blades, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no flower plumes, no pot, no soil scene.
```

**Represents:**

- Hakonechloa macra

**Use / generation notes:**

Use in repeated drifts for softness and movement. This should be lower and more cascading than tall ornamental grass.

---

## 17. Tall Ornamental Grass Fountain / Airy Plume

**Short description:** Tall grass with blades and simple plumes.

**Approximate SketchUp height:** 1.2–2.0 m for tall ornamental grass with plumes; use ~1.5–1.6 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single tall ornamental grass clump. The plant has a narrow base, many long arching blade leaves, and several simple tan plume stems rising above the foliage. Make the plumes slightly thick and geometric so they are readable. Use green, straw tan, and pale beige matte colors, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Molinia caerulea 'Transparent'
- Miscanthus sinensis 'Gracillimus'

**Use / generation notes:**

Use for vertical grassy texture and late-season movement. Molinia should be airier; Miscanthus can be denser. Use scaling and material variants rather than separate models unless needed.

---

## 18. Upright Flowering Perennial Spike Clump

**Short description:** Low foliage base with purple/blue vertical flower spikes.

**Approximate SketchUp height:** 0.45–0.85 m for most upright perennial drifts; use ~0.6 m as the default component height. Use ~0.9–1.1 m only for Salvia yangii / Russian sage style variants.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single upright flowering perennial clump. The plant has a compact green leafy base and several thick vertical purple-blue flower spikes rising above it. The flower spikes are simple geometric bead-like columns, not tiny individual flowers. Use matte green, violet, and blue-purple colors, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Salvia nemorosa
- Nepeta × faassenii
- Salvia yangii
- Astilbe, if using plume color variants

**Use / generation notes:**

Use in repeated drifts for color rhythm and upright texture. For Astilbe, use pink/white plume material and slightly softer spikes.

---

## 19. Structural Perennial Mound with Flower Heads

**Short description:** Chunky perennial mound with sturdy heads.

**Approximate SketchUp height:** 0.45–0.85 m for structural perennial mounds; use ~0.65 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single structural perennial mound. The plant has a rounded green leafy base, sturdy upright stems, and several simple round mauve or yellow flower heads above the foliage. The shapes are chunky, readable, and geometric, with flat matte colors and faceted polygons. Centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Phlomis russeliana
- Hylotelephium 'Matrona'
- Tiarella, flowering form

**Use / generation notes:**

Use when a perennial needs stronger structure than Salvia/Nepeta. This should read as a mound plus distinct flower/seed heads.

---

## 20. Small Seasonal Bulb Dot Cluster

**Short description:** Tiny symbolic spring bulb group.

**Approximate SketchUp height:** 0.08–0.25 m for symbolic seasonal bulb dots; use ~0.15–0.18 m as the default component height. Use ~0.30–0.40 m only for narcissus-like variants.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single tiny spring bulb flower cluster. The asset has several short green blade leaves and a few simple small cup-shaped flowers in white, yellow, purple, and blue. The forms are oversized enough to be readable, very simple and geometric. Centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Galanthus
- Eranthis hyemalis
- Crocus
- Muscari
- Narcissus

**Use / generation notes:**

Use symbolically. These will be small seasonal markers in SketchUp, not accurate botanical models. If Image-to-3D struggles, create simple manual bulb components instead.

---

## 21. Lavender / Dry Raised Accent Mound

**Short description:** Gray-green aromatic mound with purple spikes.

**Approximate SketchUp height:** 0.35–0.65 m for lavender mound use; use ~0.5 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single lavender mound. The plant is a compact rounded gray-green shrublet with many short narrow leaves and several upright purple flower spikes. It has a dry Mediterranean raised-bed character, simple faceted geometry, matte colors, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Lavandula angustifolia

**Use / generation notes:**

Use in sunny dry raised areas. Keep it lower and denser than upright perennial spike clumps.

---

## 22. Iris Fan-Leaf Clump

**Short description:** Upright sword-leaf fan, visually distinct from grasses.

**Approximate SketchUp height:** 0.55–0.85 m for iris fan-leaf clumps; use ~0.7 m as the default component height.

**Nano Banana image prompt:**

```text
Create a clean low-poly 3D game asset render of a single iris clump. The plant has a fan of upright sword-shaped blue-green leaves emerging from one base, with flat vertical blade geometry and a few simple purple flowers on taller stems. Use matte blue-green, medium green, and purple colors, faceted polygon shapes, centered full object, orthographic three-quarter view, plain light gray background, no labels, no text, no pot, no soil scene.
```

**Represents:**

- Iris germanica

**Use / generation notes:**

Keep separate from grasses. Iris should read as flat upright fans, not soft fountain leaves.

---

# Recommended generation sequence

Generate these first because they will carry most of the SketchUp scene:

1. Clipped hedge block
2. Tall clipped hedge screen
3. Dense broadleaf evergreen shrub mass
4. Loose deciduous boundary shrub
5. Arching flowering shrub
6. Large rounded flowering shrub
7. Climbing foliage panel
8. Bamboo screen clump
9. Low groundcover carpet
10. Broad-leaf shade clump
11. Low cascading grass
12. Tall ornamental grass
13. Upright flowering perennial spike clump
14. Lavender mound
15. Iris fan-leaf clump

Then add the specialized variants only where the scene needs them.

# Meshy Image-to-3D handoff notes

After generating the Nano Banana image:

1. Use one clean image per model.
2. Prefer centered, full-object, plain-background images.
3. Avoid using collages or asset sheets as the 3D input.
4. If using multi-view, use different views of the same object, not different plants.
5. After generation, use low-poly/remesh/export settings and do final cleanup in Blender or SketchUp.
6. For SketchUp, prioritize silhouette and scale over texture detail.

