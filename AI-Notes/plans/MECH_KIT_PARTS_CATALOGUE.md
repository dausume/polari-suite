# Mechanical kit parts: categories, variant structures, open model sources

Drafted on econ-core, 2026-11-03. This is a survey, not a Polari plan yet.

Scope rules (Dustin, 2026-11-03):
- **Categorisation first.** Shows parts, sizes and how each family varies. No material properties.
- **Non-proprietary sources only.** Vendor CAD portals (MISUMI, McMaster, TraceParts, item, Bosch Rexroth) are out. Free-to-download GrabCAD or Printables models with no licence or a non-commercial licence are out.
- **Bolt-together over fabricated.** Prefer parts that build a frame with no welding, brazing or adhesive, and ideally no machining beyond cut-to-length (and at most tapping an end hole). That is why the frame is aluminium T-slot rather than steel I/C/Z sections.

---

## 1. Categories, by importance to a kit

Tier A means a kit can't be built without it. Tier B is common, and C is nice to have.

| # | Category | Families | Tier |
|---|---|---|---|
| 1 | **Frame profiles** | T-slot extrusion, V-slot extrusion, MakerBeam-style mini profile | A |
| 2 | **Frame joints** (bolt-on) | inner corner bracket, outer L corner bracket, 3-way cube corner, flat joining plates (L / T / I / cross), end cap | A |
| 3 | **Slot fasteners** | sliding T-nut, roll-in / hammer T-nut, drop-in spring T-nut, spring-ball T-nut, T-slot bolt (DIN 186/787 style) | A |
| 4 | **Threaded fasteners: screws** | socket cap, button head, countersunk, low-head cap, hex bolt, pan head, set (grub) screw, shoulder screw, thumb screw | A |
| 5 | **Threaded fasteners: nuts** | hex, thin hex, nyloc, flange, square, wing, cap/acorn, weld nut (excluded: needs welding) | A |
| 6 | **Washers** | flat (normal / small / large-penny), spring lock, serrated, fender | A |
| 7 | **Threaded inserts and standoffs** | heat-set insert, press-in (PEM-style), wood insert, hex standoff/pillar (M-F, F-F, M-M), round spacer | A |
| 8 | **Rod and pins** | threaded rod (studding), dowel pin, spring/roll pin, clevis pin, shaft (smooth rod) | B |
| 9 | **Retaining rings** | external circlip (shaft), internal circlip (bore), E-clip | B |
| 10 | **Rotary bearings** | deep-groove ball (radial), flanged ball, pillow block (KP/UCP), thrust | B |
| 11 | **Linear motion** | profile rail plus carriage (MGN/HGH), linear ball bushing (LMxUU), shaft support (SK) and block (SC/SCS), V-slot wheel plus eccentric spacer | B |
| 12 | **Power transmission** | timing belt, timing pulley, idler, lead screw plus nut, ball screw plus nut, shaft coupling, spur gear | B |
| 13 | **Motors and mounts** (mechanical envelope only) | NEMA stepper frame sizes, motor mount plate | B |
| 14 | **Misc kit parts** | compression/extension spring, magnet, cable chain, zip tie, levelling foot, panel clip | C |

**Excluded on the "minimise steps" rule:** structural steel I/C/Z/L sections and hollow sections (welded or drilled frames), weld nuts, rivets (they need a tool and aren't reversible). Rivet nuts are borderline. They stay off the list until wanted.

---

## 2. General variant axes (shared vocabulary)

Every family is described by picking from the same set of axes. That keeps cross-family compatibility a lookup instead of special-case code.

| Axis | Kind | Examples | Used by |
|---|---|---|---|
| `standard` | enum | ISO 4762, DIN 912, ISO 7380-1, ISO 4032, ISO 7089, DIN 471, ASME B18.3 | most families |
| `thread` | key (FK) | M2, M2.5, M3, M4, M5, M6, M8, plus pitch | screws, nuts, inserts, standoffs, rod, T-nuts |
| `pitch_series` | enum | coarse (default), fine (for example M8x1.0) | threaded parts |
| `nominal_length` | stepped number | standard series 3, 4, 5, 6, 8, 10, 12, 16, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80 | screws, standoffs, pins |
| `cut_length` | continuous number | any mm | profiles, rod, shaft, rail, belt (open) |
| `head_form` | enum | cap, button, countersunk, low cap, hex, pan, none (set), shoulder | screws |
| `drive` | enum | hex socket, Torx, Phillips, Pozidriv, slot, external hex | screws |
| `point_form` | enum | flat, cone, dog, cup | set screws |
| `thread_extent` | enum | full, partial (length `b`) | screws |
| `profile_series` | key (FK) | 10 (MakerBeam), 15, 20, 30, 40, 45 | profiles, T-nuts, brackets |
| `slot_type` | key (FK) | T-slot B-type 6 mm, 8 mm, 10 mm; V-slot | profiles, T-nuts, wheels |
| `cross_section` | grid | 1x1, 1x2, 1x3, 1x4, 2x2 cells (20x20, 20x40, 20x60, 20x80, 40x40, 40x80) | profiles |
| `open_faces` | set | 4 slots, 3, 2 opposite, 2 adjacent, 1, 0 | profiles |
| `weight_class` | enum | light, standard, heavy | profiles |
| `insertion` | enum | slide-in from end, drop-in, roll-in, spring-loaded | T-nuts |
| `seal` | enum | open, ZZ (metal shield), 2RS (rubber seal) | bearings |
| `flange` | bool | flanged or plain | bearings, nuts, lead nuts |
| `bore` / `od` / `width` | number triple | 8 / 22 / 7 (608) | bearings, pulleys, couplings |
| `teeth` / `tooth_profile` / `belt_width` | ints + enum | GT2 / GT3 / T2.5 / T5 / HTD; 16T or 20T; 6, 9, 12 mm | belts, pulleys, idlers |
| `lead` / `starts` | number | T8: pitch 2, lead 2 / 8 (1 or 4 starts) | lead screws |
| `carriage_length` | enum | C (standard), H (long) | linear rails |
| `gender` | pair | M-F, F-F, M-M | standoffs |
| `handedness` | enum | right (default), left | threads, some brackets |
| `hole_count` | int | 2, 4, 6 | brackets, plates |

---

## 3. Variant data structures (part plus size plus structure, no material)

A layered shape that fits every family above:

```
PartCategory   (the table in section 1: "Slot fasteners", "Screws", ...)
  └─ PartFamily        (one standard / one geometric archetype)
       • family_id, category, standard, display_name
       • variant_axes: [axis names from section 2 that this family uses]
       • size_key: the axis that picks a row of the dimension table (usually thread or series)
       • dimension_table: { size_key → {named dimensions from the standard} }
       • length_rule: none | stepped(series, min, max per size_key) | continuous(min, max)
       • interfaces: [Interface]   ← what makes cross-family compatibility a lookup
  └─ PartVariant       (one orderable/simulatable instance)
       • family_id + a value for each variant axis (+ length)
       • derived: designation string ("ISO 4762 M5x12")
```

`Interface` is the key structural idea. Every part exposes typed features, and assembly validity is feature matching:

```
Interface { kind, key, role }
  kind: thread | slot | bore | shaft | hole_pattern | belt_tooth | rail
  key:  "M5x0.8" | "slot-B6/20" | "bore-8" | "GT2-6" | "MGN12" | "NEMA17"
  role: male | female | (for slots) rider | channel
```

So a `T-nut M5 slot-B6/20` exposes `thread M5x0.8 female` and `slot-B6/20 rider`. A `20x20 B-type` profile exposes four `slot-B6/20 channel` faces and a centre bore `thread M5x0.8 female (after tapping)`. An `ISO 4762 M5x10` exposes `thread M5x0.8 male`. Compatibility is a key match.

### 3.1 Per-family schemas

**Frame profile (T-slot / V-slot)**
```
ProfileFamily
  series: 10 | 15 | 20 | 30 | 40 | 45            # outer cell size, mm
  slot_type: B6 | B8 | I8 | B10 | V               # opening and inner shape
  cross_section: {cells_x, cells_y}               # 20x40 = {1,2}
  open_faces: bitmask per outer face slot         # 4 / 3 / 2opp / 2adj / 1
  weight_class: light | standard | heavy
  centre_bore: {dia, tappable_thread}             # 20-series ~4.2 mm, takes an M5 tap
  dims: {slot_opening, slot_depth, inner_width, wall, corner_radius}   # NopSCADlib/BOLTS fields
ProfileVariant = family + cut_length (+ end_ops: none | tapped | access_hole)
```
Size grid seen in the open libraries: 1515, 2020, 2040, 2060, 2080, 3030, 3060, 4040, 4080, plus MakerBeam 10x10 and MakerBeamXL 15x15. Topology variants for 2020: 4, 3, 2-opposite, 2-adjacent, 1 slot (BOLTS and FrameForge both use this set).

**Frame joint (bracket / plate)**
```
JointFamily
  form: inner_corner | outer_L | cube_3way | flat_L | flat_T | flat_I | flat_cross | end_cap
  series + slot_type        # which profile it fits
  hole_count, hole_thread   # 2-hole / 4-hole, M5 for 20-series
  angle: 90 (default) | 45 | 135 | adjustable
```

**Slot fastener (T-nut / T-bolt)**
```
SlotNutFamily
  insertion: slide | drop_in | roll_in (hammer) | spring_ball
  slot_type + series        # B6/20, B8/30, B8/40, B10/40
  thread                    # M3..M8 (common pairings: 20->M3/M4/M5, 30->M5/M6, 40->M6/M8)
  dims: {width, length, height, step}
```

**Screw**
```
ScrewFamily
  standard, head_form, drive, point_form?, thread_extent
  dimension_table[thread]: {pitch, dk (head dia), k (head height), s (key size), b (thread length), ...}
  length_rule: stepped(standard series, min/max per thread)
ScrewVariant = family + thread + nominal_length (+ pitch_series, handedness)
```
Standards to cover for M2 to M8: ISO 4762 (socket cap), ISO 7380-1 (button), ISO 10642 (countersunk socket), DIN 7984 (low head), ISO 4014/4017 (hex bolt, partial or full thread), ISO 7045/14583 (pan), ISO 4026/4027/4028/4029 (set screws: flat, cone, dog, cup), ISO 7379 (shoulder).

Example length ranges from the FreeCAD Fasteners WB `ISO4762range` table (min to max mm):

| M2 | M3 | M4 | M5 | M6 | M8 |
|---|---|---|---|---|---|
| 3 to 20 | 5 to 30 | 6 to 40 | 8 to 50 | 8 to 60 | 10 to 80 |

Coarse pitches: M2 0.4, M2.5 0.45, M3 0.5, M4 0.7, M5 0.8, M6 1.0, M8 1.25.

**Nut**
```
NutFamily
  form: hex | thin_hex | nyloc | flange | square | wing | cap
  standard: ISO 4032 / ISO 4035 / ISO 10511 (DIN 985) / ISO 4161 / DIN 557-562 / DIN 315 / DIN 1587
  dimension_table[thread]: {s (across flats), e (across corners), m (height)}
```

**Washer**
```
WasherFamily
  form: flat | small | large (penny/fender) | spring | serrated
  standard: ISO 7089 / ISO 7092 / ISO 7093 / DIN 127 / DIN 6798
  dimension_table[thread]: {d1 (inner), d2 (outer), h}
```

**Insert / standoff**
```
InsertFamily     install: heat_set | press_in | wood_thread ; thread ; length: short|long|explicit ; dims {od, length, knurl}
StandoffFamily   section: hex | round ; gender: MF|FF|MM ; thread ; body_length (stepped) ; across_flats
```

**Rod / pin / retaining ring**
```
ThreadedRod      thread ; cut_length                       (DIN 976)
Pin              form: dowel | spring | clevis ; dia ; nominal_length   (ISO 2338/8734/8752, ISO 2341)
RetainingRing    form: external | internal | e_clip ; nominal (shaft or bore) dia   (DIN 471 / 472 / 6799)
```

**Bearing**
```
RadialBearing    series code (608, 623, 624, 625, 688, 6200...) -> {bore, od, width} ; seal: open|ZZ|2RS ; flange: bool
LinearBushing    LM{d}UU : d in 3,4,5,6,8,10,12,16 ; length: std|L (long) ; open: bool
PillowBlock      KP / UCP code -> {bore, mount_hole_spacing}
```

**Linear motion**
```
ProfileRail      size: MGN5|7|9|12|15, HGH15|20 ; cut_length ; hole_pitch
Carriage         rail_size ; length: C|H
ShaftSupport     SK{d} / SC{d}UU / SCS{d}UU : d in 8,10,12,16
VWheel           type: mini|solid|xtreme ; bore (5 typ) ; + eccentric spacer height
```

**Power transmission**
```
Belt             tooth_profile: GT2|GT3|T2.5|T5 ; width: 6|9|12 ; open (cut_length) | closed loop (teeth count)
Pulley/Idler     tooth_profile ; teeth: 16|20|... ; bore: 5|8 ; belt_width ; toothed|plain idler
LeadScrew        dia (T8 common) ; pitch ; starts -> lead (2 or 8) ; cut_length
LeadNut          screw ; form: flanged|anti_backlash ; (ball screw SFU1204/1605/1610)
ShaftCoupling    bore_a x bore_b (5x8 common) ; form: rigid | jaw | beam (flex)
SpurGear         module ; teeth ; bore ; face_width ; pressure_angle (20)
```

**Motor envelope**
```
StepperFrame     NEMA 8|11|14|17|23 ; body_length ; shaft {dia, length, D-flat} ; mount {bolt circle, thread}
```

---

## 4. Open model and data sources (non-proprietary only)

| Source | Licence | What it gives | Families covered |
|---|---|---|---|
| [FreeCAD Fasteners Workbench](https://github.com/shaise/FreeCAD_FastenersWB) | GPL-2.0 | **Parametric FreeCAD fasteners** from per-standard CSV dimension tables (`FsData/*def.csv`, plus `*range` length tables) | Screws (ISO 4762/7380/10642/4014/4017, DIN 912/7984...), set screws 4026 to 4029, nuts (ISO 4032/4035/10511, DIN 557/562/985, T-slot nuts DIN 508 and GN 505/506/507), washers, pins, retaining rings DIN 471/472/6799, heat-set inserts, PEM press-ins, PCB standoffs, threaded rod, DIN 103 trapezoidal rod. **Best source for the M2 to M8 tables.** |
| [BOLTS](https://github.com/boltsparts/BOLTS) ([parts index](https://boltsparts.github.io/en/parts/index.html)) | Repo GPL-3.0; data collections declare their own (extrusions: LGPL-2.1+) | FreeCAD and OpenSCAD standard parts with a typed spec (`data/*.blt`) | `extrusions.blt`: generic T-slot 20x20 in 4/3/2-opp/2-adj/1 slot variants plus V-slot 20x20; hex and socket fasteners; nuts; washers; bearings. Steel I/C/L/Z profiles are skipped (weld-oriented). |
| [NopSCADlib](https://github.com/nophead/NopSCADlib) (`vitamins/`) | GPL-3.0 | OpenSCAD "vitamins": one dimension tuple per variant, the cleanest variant tables | Extrusions (MakerBeam, MakerBeamXL, E1515, E2020, E2020t, E2040/60/80, E3030/3060, E4040/4040t/4080), extrusion corner brackets (inner corner and 3D cube 2020/3030/4040), screws M2 to M8 in cap/cs/dome/pan/hex/low-cap/shoulder/grub, nuts including **sliding T-nuts M3 to M6, hammer nuts M3/M4, ball T-nut M8**, washers, heat-set inserts F1BM/CNCKM M2 to M5, pillars, MGN5 to 15 and HGH15/20 rails plus C/H carriages, LM3 to 16 UU bushings, SK8 to 16, ball bearings (608, 62x, MR/F series), GT2/GT3/T2.5/T5 belts and pulleys, lead nuts (LSN8x2/8x8, SFU1610), couplings 5x8, NEMA 8 to 23 steppers, circlips, springs, magnets, woodworking T-track |
| [FrameForge](https://github.com/lukh/frameforge) | LGPL-3.0 | FreeCAD workbench for **beam frames with cut lists**; profile JSON library | `aluminium_extrusion.json`: V-slot 20x20 to 20x80 and T-slot 20x20 in 4/3/2/2-opp/1 slot variants; also cut-to-length, mitre and end treatments. Fits the bolt-together frame approach. |
| [FrameForge mod](https://github.com/q921057310-byte/FrameForgeMod) | LGPL-3.0 | Fork with wider 20 to 60 series (CN/EU), M6/M8/M10 connector options | Profiles and connectors. **Caution:** README says the code is AI-generated. Use for its data, verify it. |
| [FreeCAD-library](https://github.com/FreeCAD/FreeCAD-library) | CC-BY 3.0 (per-part attribution) | Static FreeCAD/STEP models | `Mechanical Parts/`: Fasteners, Bearings, Coupling, Pulleys, Chains, Wheels, Mountings, Profiles EN, cable-chain-links |
| [BOSL2](https://github.com/BelfrySCAD/BOSL2) (`screws.scad`, `threading.scad`) | BSD-2-Clause | OpenSCAD ISO/UTS screws and nuts generated from spec, plus nut traps | Screws and nuts, any M size; thread geometry. Most permissive licence here. |

**Checked and excluded:**
- **MISUMI / McMaster / TraceParts / item / Bosch** CAD: proprietary download terms.
- **[freecad-aluframe-tools](https://github.com/palmhoej/freecad-aluframe-tools):** the code is LGPL-2.1, but its data is the MISUMI series 5/6/8 catalogue with MISUMI order codes, a vendor's catalogue. It could be used as a cross-check, not as source data.
- **[Printables OpenBuilds V-slot models](https://www.printables.com/model/1558760-high-precision-cad-models-of-openbuilds-v-slot-ext)** and similar Printables, MakerWorld and GrabCAD uploads: the licence is per upload and often CC-BY-NC or missing.
- **OpenBuilds V-Slot itself** is published as open hardware. I haven't confirmed its licence terms, so it is unverified for now.

---

## 5. Notes for bringing this into Polari later (not started)

- Polari has none of these today. The only threaded part is the M8x1.25 rod in `motors/m1_product_seed.py`. `composition` has `fm-fastener-back-out` as a NOT MODELLED gap, and `PART_ARCHETYPES_PLAN.md` lists `fastener` under `retention_scheme`.
- The shape in section 3 (family → dimension table keyed by size → variant, plus typed `Interface`s) mirrors how pcb works: PartBoard plus footholds, with connection by matching keys.
- Suggested first seed: 2020 B-type T-slot (5 topologies) + inner/L/cube brackets + T-nuts M3/M4/M5 + ISO 4762, ISO 7380, ISO 4032 and ISO 7089 for M2 to M8 + 608/625 bearings. That alone builds a bolt-together frame with no welding or machining beyond cutting to length.
- Import path: FastenersWB CSVs (GPL-2.0) and NopSCADlib tuples (GPL-3.0) are dimension data. BOSL2 (BSD-2) is the least restrictive geometry generator. Licence gate per the suite's usual `AI-Notes/evaluations/*_LICENSE_GATE.md` before vendoring anything.

---

## 6. Data: download sizes, sources, materials (2026-11-03)

Machine-readable files are in `data/`. Regenerate them with `python3 data/build_data.py`.
- `sources.json` / `sources.csv`: each library's repo, maintainer, licence, last push, full-clone size, working-tree size split by models / images / data / code, the smallest useful subset, where the dimensions come from, and whether material is recorded.
- `part_materials.json` / `part_materials.csv`: typical materials per part family. `basis` is `standard` when a standard defines the grade, `common` for what kit suppliers sell, `varies` otherwise.
- `measured_*.json`: the raw GitHub git-tree measurements.
- `materials_registry.json` / `.csv` (from `build_materials.py`): 51 materials (elastomers, plastics, metals, fibres, coatings, additives). Each has its feedstocks with IARC class, end of life, a bio-based option, caveats, and a status: `polari_preferred` / `polari_acceptable` / `legacy_harmful`. Legacy rows name what replaces them (`replaced_by`).
- `part_material_roles.json` / `.csv`: for each part family, the Polari default material(s), the acceptable alternatives, and the legacy/harmful materials found in existing kits, kept for comparison.
