# Composting-loop data license gate (cmp-0 research pass)

**Date:** 2026-08-20 · **Arc:** cmp (COMPOSTING_LOOP_PLAN.md) · **Status:
ALL FIVE SOURCES GREEN** — full per-source reports below (5 parallel
research agents, primary-source verified). Summary verdicts live in the
plan's "Research verdicts" section; this file is the durable detail.

Per project license policy (GPLv3; NC = hard blocker): every verdict
below checked the actual license/terms, and every table records values
as cited facts (Feist) — never vendored text. UNVERIFIED labels are
kept honest; resolve before relying on those specific rows.

---

# cmp-0 research — USDA refuse factors (agent report, 2026-08-20)

**VERDICT: GREEN.** SR28 (ars.usda.gov) is the only machine-readable source of refuse percent + description; it is a US-government work published without restriction (FDC, which subsumed SR, states its data are public domain under CC0 1.0). **Recommended vendoring path: download `sr28asc.zip` from ARS, extract `FOOD_DES.txt` fields `NDB_No`, `Ref_desc`, `Refuse`, and join to the pantry's fdc_ids via FDC's `sr_legacy_food.csv` (fdc_id ↔ NDB_number) — beware the leading-zero mismatch (FDC stores `9003`, SR28 stores `09003`).** Do NOT use FAO/INFOODS edible-portion data (CC BY-NC-SA = NC = hard blocker for this project).

## Q1 — Where machine-readable refuse lives

**FDC SR Legacy bulk CSV: refuse was DROPPED.** Agent downloaded and unzipped `FoodData_Central_sr_legacy_food_csv_2018-04.zip` (from https://fdc.nal.usda.gov/download-datasets; SR Legacy = final release April 2018, never updated). 19 files; **no refuse column exists anywhere.** `sr_legacy_food.csv` header is exactly `"fdc_id","NDB_number"` — the SR28 `Refuse`/`Ref_desc` fields were not carried over. Only occurrences of "refuse" are free-text portion modifiers in `food_portion.csv` — not a data field.

**SR28 at ARS: still available, has the fields.** Page: https://www.ars.usda.gov/northeast-area/beltsville-md-bhnrc/beltsville-human-nutrition-research-center/methods-and-application-of-food-composition-laboratory/mafcl-site-pages/sr11-sr28/ — `sr28asc.zip` (6.0 MB, direct: https://www.ars.usda.gov/ARSUserFiles/80400535/DATA/SR/sr28/dnload/sr28asc.zip), plus Access/Excel forms, May-2016 patch, `sr28_doc.pdf`. Verified by download: `FOOD_DES.txt` has 8789 records, `^`-delimited with `~` text quoting; field 8 = `Ref_desc`, field 9 = `Refuse` (integer percent).

**FDC API: NO refuse.** Live call to https://api.nal.usda.gov/fdc/v1/food/170567 — "refuse" appears nowhere in the JSON.

## Q2 — License

- **FDC:** https://fdc.nal.usda.gov/api-guide states data "are in the public domain and they are not copyrighted. They are published under CC0 1.0 Universal" (attribution requested, not required). CC0 is GPLv3-compatible.
- **SR28:** ARS page carries no license text; SR28 is a US federal government work (17 U.S.C. §105, public domain). Ag Data Commons record lists CC0 but returned 403 to fetchers — UNVERIFIED at page level; §105 + FDC CC0 statement sufficient basis regardless.

## Q3 — Coverage: verified SR28 values (from downloaded FOOD_DES.txt)

| Item | NDB_No | fdc_id | Refuse % | Ref_desc |
|---|---|---|---|---|
| Apples, raw, with skin | 09003 | 171688 | 10 | Core and stem |
| Bananas, raw | 09040 | 173944 | 36 | Skin |
| Oranges, raw, all comm. var. | 09200 | 169097 | 27 | Peel and seeds |
| Avocados, raw, all comm. var. | 09037 | 171705 | 26 | Seed and skin |
| Potatoes, russet, flesh and skin, raw | 11353 | 170027 | 25 | Parings and trimmings |
| Egg, whole, raw, fresh | 01123 | 171287 | 12 | Shell |
| Broccoli, raw | 11090 | 170379 | 39 | Leaves and tough stalks with trimmings |
| Sweet potato, raw | 11507 | — | 28 | Parings and trimmings |
| Onions, raw | 11282 | — | 10 | Stem ends, sprouts and defects |
| Garlic, raw | 11215 | — | 13 | Knob and skin |
| Carrots, raw | 11124 | — | 11 | Crown, tops and scrapings |
| Celery, raw | 11143 | — | 11 | Roots and trimmings |
| Cucumber, with peel, raw | 11205 | — | 3 | Ends |
| Kale, raw | 11233 | — | 28 | Stem ends, tough stems, midribs |
| Lettuce, cos or romaine | 11251 | — | 6 | Core |
| Mushrooms, white, raw | 11260 | — | 3 | Trimmings |
| Spinach, raw | 11457 | — | 28 | Large stems and roots |
| Strawberries, raw | 09316 | — | 6 | Caps and stems |
| Blueberries, raw | 09050 | — | 5 | Stems and green/spoiled berries |
| Tomatoes, red, ripe, raw | 11529 | — | 9 | Core and stem ends |
| Peppers, sweet, red, raw | 11821 | — | 18 | Stem ends, seed and core |

Zero-refuse confirmed: chicken breast skinless/boneless (05062/171077)=0; cod (15015)=0; salmon Atlantic wild (15076)=0; tilapia (15261)=0; flour (20081), rice white (20444), oats (20038), olive oil (04053), sugar (19335), salt (02047) all = 0.

**Gotchas for the pantry mapping:**
1. **Almonds (12061 / fdc 170567) Refuse = 60 "Shells"** — SR assumes in-shell as-purchased; store-bought shelled almonds → 0. Vendored CSV needs an override / as-purchased-form flag.
2. **Boneless beef chuck NOT refuse-0**: 13293 boneless lean-only chuck (fdc 169445) = 19% ("Connective tissue 6%, seam fat 13%"); Denver cut boneless (13356) = 5%. Which applies depends on whether the household trims.
3. **Pork loin whole lean+fat (10020 / fdc 167818) = 22% "Bone"** — that SR item is bone-in; a boneless-loin pantry entry should use a boneless SR item or zero it.
4. Join gotcha: FDC `NDB_number` has leading zeros stripped; SR28 `NDB_No` is zero-padded 5-char. Normalize before joining.

## Q4 — Alternatives

- **FAO Global Nutrient Conversion Table** (edible-portion coefficients): CC BY-NC-SA 3.0 IGO — **NC ⇒ hard blocker, do not vendor**. https://openknowledge.fao.org/items/85fb7d01-2ed3-4abb-b12b-b876fa93e4bc
- **USDA Foundation Foods** (CC0): per-sample `food_component` weights for some foods, no clean per-food refuse percent — not a drop-in replacement.
- Net: SR28 = the only CC0 machine-readable refuse table; frozen (Sept 2015, rev. May 2016) — fine for a vendored CSV.

---

# cmp-0 research — C:N / moisture feedstock tables (agent report, 2026-08-20)

**VERDICT: YES — transcribe the numeric values into a cited CSV. Recommended primary source = USDA NRCS National Engineering Handbook, Part 637, Ch. 2 "Composting" (210-VI-NEH, Amend. 40, Nov 2010), Table 2A-1 — a US-government work (public domain, 17 USC §105) that carries the SAME numbers as NRAES-54 Appendix A. Cite NRAES-54 as the underlying compilation for provenance.**

## 1. Cornell / NRAES-54 status

- compost.css.cornell.edu is UP (C/N page: https://compost.css.cornell.edu/calc/cn_ratio.html; Compost Chemistry: https://compost.css.cornell.edu/chemistry.html; footer "Cornell Waste Management Institute ©1996 Cornell University"). Old framed handbook Appendix A page is 404; the table now lives at **http://cwmi.css.cornell.edu/AppendixATable1OFCH.pdf** (live, fetched).
- **NRAES-54 copyright (verified from the 1992 PDF's copyright page)**: "© 1992 by Northeast Regional Agricultural Engineering Service. All rights reserved." (NRAES disbanded 2011; Cornell eCommons hosts it; eCommons license label UNVERIFIED — page blocked automated fetch.)
- **Transcription is fine**: numeric measurements are uncopyrightable facts (Feist), re-expressed in our own CSV structure. Belt-and-suspenders: identical numbers appear in the public-domain NRCS NEH Table 2A-1 — cite that as primary. Attribution line to carry:
  > "Values from USDA NRCS, National Engineering Handbook, Part 637 Environmental Engineering, Chapter 2 Composting, Table 2A-1 (210-VI-NEH, Amend. 40, Nov 2010); compiled from Rynk, R. (ed.), On-Farm Composting Handbook, NRAES-54, 1992, Appendix A. Representative literature values, not true ranges."

## 2. Sources ranked

- **BEST — USDA NRCS NEH Part 637 Ch. 2** (https://directives.nrcs.usda.gov/sites/default/files2/1720464003/Chapter%202%20-%20Composting.pdf, fetched + text-extracted): Table 2A-1 "Typical characteristics of selected raw materials" (%N, C:N, moisture, bulk density) — identical to NRAES-54 App. A; its Appendix 2B is explicitly excerpted from NRAES-54. Public domain.
- **NMSU Extension Guide H-110 "Backyard Composting"** (https://pubs.nmsu.edu/_h/H110/): explicit "Contents of publications may be freely reproduced for educational purposes." Good household-scale secondary.
- **EPA Composting at Home** (https://www.epa.gov/recycle/composting-home): public domain but qualitative only — not sufficient alone.

## 3. Values ([A] = NRCS NEH 637 Table 2A-1 == NRAES-54 App. A; [B] = NMSU H-110 Table 1; C:N wt:wt; moisture % wet basis; "avg (range)")

| Feedstock | Row used | C:N | Moisture % | Src |
|---|---|---|---|---|
| Vegetable scraps | Vegetable produce / vegetable wastes | 19 / 11–13 | 87 / — | A |
| Fruit waste | Fruit wastes | 40 (20–49) | 80 (62–88) | A |
| Coffee grounds | Coffee grounds | 20 | — | A (B: 20) |
| Eggshells | — not in A or B | UNVERIFIED — no primary-source row; flag as mineral amendment (CaCO₃), negligible C/N contribution | — | — |
| Grass clippings | Grass clippings | 17 (9–25) | 82 | A (B: 12–15) |
| Dry leaves | Leaves | 54 (40–80) | 38 | A (B: 30–80) |
| Straw | Straw—general (wheat) | 80 (48–150); wheat 127 (100–150) | 12 (4–27) | A (B: 40–100) |
| Shredded cardboard | Corrugated cardboard | 563 | 8 | A |
| Paper | Newsprint / domestic-refuse paper | 398–852 / 127–178 | 3–8 / 18–20 | A (B "paper": 170–200) |
| Sawdust | Sawdust | 442 (200–750) | 39 (19–65) | A (B: 200–500) |
| Wood chips | Hardwood / softwood chips | 560 (451–819) / 641 (212–1313) | — | A |
| Poultry manure w/ bedding | Broiler litter | 14 (12–15) | 37 (22–46) | A (laying-hen manure: 6 (3–10), 69%) |
| Mixed kitchen food waste | Garbage (food waste) | 14–16 | 69 | A (B "food scraps": 15) |

**Target ranges (provenance):**
- NRAES-54 Table 2.1 (verified, 1992 PDF p.7): C:N reasonable **20:1–40:1, preferred 25:1–30:1**; moisture reasonable **40–65%, preferred 50–60%**.
- NRCS NEH 637 Ch.2 (public-domain restatement): initial C:N 20:1–40:1; moisture ideally ~60% after mixing; 50–70% = wrung-out sponge.
- Cornell chemistry page: ideal C/N ~30:1. NMSU H-110: ~30:1, moisture 40–60%.

## 4. Kinetics prior (one line)

NEH 637: decomposition slows as C:N rises above optimum (N-limited); C:N as low as 14:1 still composts. Quantitative first-order rate constants: Haug, *Practical Handbook of Compost Engineering* (1993) — copyrighted CRC book; values-as-facts fine, UNVERIFIED this pass.

Local artifacts in scratchpad: neh637ch2.pdf (+ .txt), nraes54.pdf.
Sources: Cornell C/N page · Cornell chemistry page · Cornell Appendix A PDF · NRCS NEH 637 Ch.2 PDF · NRAES-54 PDF (https://campus.extension.org/pluginfile.php/48384/course/section/7167/NRAES%20FarmCompost%20manual%201992.pdf) · eCommons record (https://ecommons.cornell.edu/items/c66de614-e524-46a3-a4cb-031c9a1e7e11) · NMSU H-110 · EPA Composting at Home.

---

# cmp-0 research — livestock feed legality (agent report, 2026-08-20)

**VERDICT:** US federal law here is public-domain (17 U.S.C. 105) and directly transcribable as cited, fail-closed rules. The fail-closed rule set in one paragraph: *Any* food waste that contains meat/animal material — or any waste of any character (including vegetable scraps) that has **been associated with** such material — is "garbage" under the Swine Health Protection Act (7 U.S.C. 3801–3813) and 9 CFR part 166, and may not be fed to swine unless treated (boiled 212 °F / 100 °C for 30 min) at a **licensed** facility; the single federal carve-out is a household feeding its **own** ordinary household waste **directly** to swine **on the same premises** as the household. That carve-out dies the moment the waste leaves the premises (a neighbor's/receiving farm is fully subject to the rule). State law layers on top and is frequently **stricter** — ~23–25 states prohibit garbage feeding outright and will issue no license (9 CFR 166.2(d)–(e) expressly preserves state bans), so the app must fail closed to "check your state" for any swine destination. Chickens: no federal prohibition for a backyard flock (fail-closed on state law only). Pets: no legality layer at all federally for home feeding — toxicity only. Selling/donating scraps off-premises adds FDA animal-food (FSMA) considerations, but private residences are not FDA "facilities."

## Q1 — Swine (SHPA + 9 CFR part 166)

- **Definition of "garbage" — 9 CFR 166.1** (mirrors 7 U.S.C. 3802(2)): "all waste material derived in whole or in part from the meat of any animal (including fish and poultry) or other animal material, **and other refuse of any character whatsoever that has been associated with any such material**, resulting from the handling, preparation, cooking or consumption of food, except that such term shall not include waste from ordinary household operations which is fed directly to swine on the same premises where such household is located." → **Vegetable waste that touched meat (shared plate/cutting board/bin) IS garbage.** App rule: any commingled kitchen waste = garbage unless meat-free by construction. (Exact "processed product" carve-out text UNVERIFIED — full 166.1 not retrieved.) https://www.law.cornell.edu/cfr/text/9/166.1
- **Cooking requirement — 9 CFR 166.7**: "Garbage shall be heated throughout at boiling (212 °F. or 100 °C. at sea level) for 30 (thirty) minutes," with agitation (except steam equipment); treatment at a facility operated by a valid license holder — 9 CFR 166.2(a); licensing 9 CFR 166.10. https://www.law.cornell.edu/cfr/text/9/166.7
- **Household exemption — CORRECTION to the plan's pointer**: NOT in 9 CFR 166.15; it lives inside the *definition of garbage itself* (166.1 / 7 U.S.C. 3802(2)). Three prongs, ALL required: (a) ordinary household operations waste, (b) fed *directly*, (c) swine *on the same premises as the household*. 9 CFR 166.15 is actually "State status" (APHIS website lists of prohibit/allow states).
- **State layer — confirmed**: 9 CFR 166.2 — regs "shall not be construed to repeal or supersede State laws that prohibit feeding of garbage to swine"; in a prohibition state no license will be issued. ~23–25 states prohibit outright; **Michigan** confirmed (PA 466 of 1988, MSU Extension). States allowing licensed feeding include AK, AZ, AR, CA, CO, CT, FL, HI, IN, ME, MA, MN, MO, NV, NH, NJ. Authoritative list = APHIS state map (fetch timed out; per-state status UNVERIFIED → resolve per user; exactly the fail-closed behavior wanted). https://www.aphis.usda.gov/sites/default/files/swine-health-protection-map.pdf · https://www.aphis.usda.gov/sites/default/files/fs-swine-producers-garbage-feeding.pdf · https://www.canr.msu.edu/news/michigan-farms-may-not-cook-and-feed-garbage-to-swine

## Q2 — Poultry

- **No federal rule** prohibits kitchen scraps to a backyard/household flock (SHPA is swine-only). EPA framing: if no meat/animal materials, no federal law applies, though state law may; several states restrict scrap feeding to poultry — state check per user. (EPA page confirms "Regulations vary in each state"; the exact "no meat → no federal law" sentence UNVERIFIED verbatim, direction confirmed.) https://www.epa.gov/sustainable-management-food/reduce-wasted-food-feeding-animals + Harvard FLPC *Leftovers for Livestock*.
- **UK/EU contrast:** catering/kitchen waste to any farmed animal (incl. poultry, pigs) is banned — Regulation (EC) No 1069/2009 Art. 11(1)(b). No US blanket ban.
- **21 CFR 589.2000** (ruminant feed / BSE): mammalian-tissue protein in ruminant feed = adulterated; excludes blood products, gelatin, tallow, milk, pure porcine/equine (§(a)(1)). Not this project's species — rule stub only. https://www.law.cornell.edu/cfr/text/21/589.2000

## Q3 — Cats/dogs

- **Confirmed: no federal prohibition** on feeding household scraps to your own pets. FDA authority (FFDCA) attaches to pet food *marketed/distributed*; AAFCO is not a government agency (model regs gain force via state adoption; govern products for sale, not the home bowl). The app layer for pets = toxicity, not legality. https://www.fda.gov/animal-veterinary/animal-health-literacy/information-marketing-pet-food-product

## Q4 — Leaving the household (give-away / local sale)

- **Swine: the garbage law attaches to the receiving farm.** Same-premises prong fails on transfer → the material IS garbage; 9 CFR 166.2(a) "No person shall feed **or permit the feeding** of garbage to swine unless… treated… at a [licensed] facility" binds the receiving feeder (and arguably the giver via "permit"). In a prohibition state the transfer-to-pigs route is illegal. App rule: `destination != same_premises → licensed-garbage pathway or BLOCK`.
- **FDA/FSMA:** animal food is "food" under FFDCA, BUT (a) "The private residence of an individual is not a facility" (21 CFR 1.227) → household give/sell never triggers registration or part 507; (b) farms exempt from registration (21 CFR 1.226); (c) for restaurant/food-business → farm flows: 21 CFR 507.12 human-food-by-products exemption (hold/distribute per §§507.28, 117.95). Household → farm flows carry only SHPA/state layer + general adulteration. https://www.law.cornell.edu/cfr/text/21/1.227 · https://www.law.cornell.edu/cfr/text/21/507.12

## Suggested fail-closed rule encoding

1. `species == swine AND waste is/was associated with any meat/fish/poultry/animal material` → GARBAGE. Allowed only if (`own household` AND `fed directly` AND `same premises`) OR (`licensed facility` AND `boiled 212°F/100°C ≥30 min` AND `state allows licensing`). Default: BLOCK + "state check required" (cite 9 CFR 166.1, 166.2, 166.7).
2. `species == swine AND destination != household premises` → household exemption VOID; licensed pathway or BLOCK (166.1 + 166.2(a)).
3. `species == chicken` → no federal bar for household flock; SHOW state-check gate.
4. `species in {cat, dog}` → no legality gate federally; defer to toxicity engine.
5. Sale/distribution from a non-household food business → 21 CFR 507.12/507.28 pathway note.

---

# cmp-0 research — per-species feed lists (agent report, 2026-08-20)

**VERDICT: GREEN — all four species' acceptance/prohibition lists are sourceable from authoritative, citable references (ASPCA, Merck Vet Manual, UF/IFAS, OSU/CSU/Iowa State/Purdue extension). Transcribing facts (food, toxin, severity) into original cited data rows is lawful under US law (facts are uncopyrightable, Feist v. Rural); no source examined carries explicit data-reuse prohibitions. Do NOT copy prose or wholesale table layouts.**

## 1. CHICKENS

Primary factsheets: UF/IFAS Extension Holmes County "10 Foods You Should Never Feed Chickens" (Kalyn Waters, 2026) — fetched and verified; Oklahoma State Extension AFS-8202 "Backyard Flock Production" — content via search excerpt only, page returns 403 to fetchers (mark rows citing it VERIFIED-VIA-EXCERPT).

| Food | Status | Reason | Source |
|---|---|---|---|
| Avocado (esp. skin, pit, leaves) | prohibited | Persin toxin — breathing problems, weakness, cardiac damage; flesh lowest in persin but extension says avoid entirely | https://blogs.ifas.ufl.edu/holmesco/2026/05/25/10-foods-you-should-never-feed-chickens/ |
| Raw/dry beans | prohibited | Phytohaemagglutinin (PHA) — severe digestive poisoning, can be fatal; cooked beans OK | same UF/IFAS URL |
| Green potato peels / raw green potato | prohibited | Solanine — nervous system + digestive toxicity | same UF/IFAS URL; also OSU AFS-8202 |
| Moldy/rotten food | prohibited | Mold toxins (mycotoxins) — respiratory/digestive harm; UF/IFAS rule of thumb: "if you would not eat it yourself, do not feed it" | same UF/IFAS URL |
| Chocolate | prohibited | Theobromine + caffeine — hyperactivity, seizures, death | same UF/IFAS URL |
| Coffee/caffeine | prohibited | Nervous system + cardiac effects, potentially fatal | same UF/IFAS URL |
| Salty foods | prohibited | Dehydration, kidney damage | same UF/IFAS URL; OSU AFS-8202 |
| Onion | caution (quantity) | Large amounts damage red blood cells → anemia; UF/IFAS explicitly says small amounts "usually not harmful" | same UF/IFAS URL |
| Alcohol | prohibited | Disorientation, dehydration, respiratory failure | same UF/IFAS URL |
| Apple seeds / stone-fruit pits | prohibited | Cyanogenic — release cyanide when crushed | same UF/IFAS URL |
| Citrus | caution — **sources disagree** | UF/IFAS factsheet does NOT list citrus at all (supports "myth/overblown"); OSU AFS-8202 says scraps should "not be salty or have citrus or be moldy"; secondary claim is reduced calcium absorption → soft shells. Record as caution-in-quantity, note disagreement | https://extension.okstate.edu/fact-sheets/backyard-flock-production.html (excerpt); UF/IFAS URL (absent) |
| Rhubarb | prohibited | Listed avoid by OSU (oxalates — mechanism not stated in excerpt) | OSU AFS-8202 (excerpt) |
| Scraps overall | rule | ≤ 10% of daily diet; rest complete feed. OSU: "no more than 10 percent of the daily diet"; Colorado State Extension: treats ≤ 10% of daily diet; UF/IFAS: "small portion" (no number) | OSU AFS-8202; https://extension.colostate.edu/resource/raising-poultry-the-organic-way-disease-control-and-feeding/ |

## 2. DOGS

Primary: ASPCA "People Foods to Avoid Feeding Your Pets" (fetched) — https://www.aspca.org/pet-care/aspca-poison-control/people-foods-avoid-feeding-your-pets ; Merck Vet Manual "Food Hazards" (fetched) — https://www.merckvetmanual.com/special-pet-topics/poisoning/food-hazards

| Food | Status | Reason | Source |
|---|---|---|---|
| Chocolate/cocoa/coffee | prohibited | Methylxanthines (theobromine + caffeine), CNS stimulation; darker = worse (baking chocolate/cocoa powder highest). Merck: ~1 oz milk chocolate per lb body weight potentially fatal | ASPCA; Merck food-hazards |
| Xylitol | prohibited (severe) | Insulin release → hypoglycemia within ~30 min; liver damage within 12–24 h | ASPCA; Merck |
| Grapes/raisins (also tamarind, cream of tartar) | prohibited (severe) | **Tartaric acid** — 2021+ finding CONFIRMED carried by both sources; dogs lack organic-acid transporters → accumulates in proximal renal tubule cells → acute kidney injury. Merck threshold: >1 grape/raisin per 4.5 kg body weight poses risk | https://www.merckvetmanual.com/toxicology/food-hazards/grape-raisin-and-tamarind-vitis-spp-tamarindus-spp-toxicosis-in-dogs ; ASPCA |
| Onion/garlic/leek/chive (Allium) | prohibited | Oxidative red-blood-cell damage → GI irritation + hemolytic anemia | ASPCA |
| Macadamia nuts | prohibited | Weakness, incoordination, tremors, hyperthermia within 12 h; resolves 12–72 h (mechanism unknown — record reason as "unknown toxin, transient neuromuscular syndrome") | ASPCA; Merck |
| Alcohol | prohibited | Vomiting, incoordination, CNS depression, respiratory depression, death | ASPCA |
| Raw yeast dough | prohibited | Gastric expansion/bloat + potential GDV; fermentation produces ethanol → alcohol poisoning (seizures, coma) | ASPCA; Merck |
| High-fat scraps (grease, trimmings, nuts) | caution | Vomiting, diarrhea, pancreatitis risk | ASPCA (nuts/fatty entry) |
| Salt/salty snacks | caution/prohibited in quantity | Sodium ion toxicosis — thirst, vomiting, tremors, seizures, death | ASPCA |
| Avocado | caution (dogs) | ASPCA: primary concern is birds/rabbits/equines/ruminants, not dogs; Merck lists cardiac/mammary damage in some species. Record dog status = caution, not top-tier toxin | ASPCA; Merck |
| Raw meat/eggs/bones | caution | Salmonella/E. coli; raw egg avidin blocks biotin; bones = obstruction/injury | ASPCA |
| Citrus, coconut, dairy | caution (mild) | Citrus: citric acid/oils → minor GI upset in small amounts; coconut flesh/milk → loose stools; dairy: lactase deficiency → diarrhea | ASPCA |

## 3. CATS

| Food | Status | Reason | Source |
|---|---|---|---|
| Onion/garlic/chive (Allium) | prohibited — **more sensitive than dogs, CONFIRMED** | ASPCA verbatim position: RBC damage/anemia; "cats are more susceptible, dogs are also at risk depending on amount" | ASPCA people-foods URL above |
| Chocolate/caffeine | prohibited | Methylxanthines (same as dogs) | ASPCA; Merck food-hazards |
| Alcohol / raw yeast dough | prohibited | Same mechanisms as dogs (ethanol; dough expansion + fermentation) | ASPCA |
| Milk/dairy | **caution, not toxin** | Lactase deficiency → osmotic diarrhea; digestive upset only | ASPCA |
| Raw fish (habitual) | prohibited as staple / caution as treat — **VERIFIED** | Thiaminase destroys thiamine (B1) → deficiency: ventroflexion of head, vestibular signs, ataxia, seizures, death; carp/herring esp. rich; experimental onset 23–40 days; cooking destroys thiaminase | Merck Vet Manual, Nutritional Disorders of the Spinal Column and Cord: https://www.merckvetmanual.com/nervous-system/diseases-of-the-spinal-column-and-cord/nutritional-disorders-of-the-spinal-column-and-cord-in-animals |
| Liver in excess (habitual) | caution/prohibited as staple — **VERIFIED** | Hypervitaminosis A: "cats fed excess vitamin A, usually from diets consisting largely of liver, develop extensive exostoses, most prominent in the cervical and thoracic spine"; neck pain/rigidity, forelimb lameness; existing lesions permanent | same Merck spinal-disorders URL |
| Grapes/raisins | prohibited (precaution) | Merck: kidney failure "reported in 1 cat" — dogs are the established species; record for cats as precautionary prohibition | Merck grape-toxicosis URL above |

## 4. PIGS (toxicity layer only; 9 CFR 166 legality covered elsewhere)

| Food | Status | Reason | Source |
|---|---|---|---|
| Raw potato, green parts/peels/sprouts | prohibited raw; cooked OK | Solanine/glycoalkaloids — GI + nervous system damage; cooking improves palatability and digestibility (Purdue PIH: cooked potatoes usable feedstuff); note glycoalkaloids are heat-stable, so trim green parts even before cooking | Purdue PIH-07-06-01 By-Products in Swine Diets: https://www.extension.purdue.edu/extmedia/as/07-06-01.pdf (excerpt) |
| Salty scraps + restricted water | prohibited (severe) — the operative risk is WATER DEPRIVATION | Merck salt toxicosis (fetched): lethal ~2.2 g/kg NaCl in swine; even normal-salt diets become toxic after water restriction; 1–5 days limited water → intermittent seizures, blindness, circling, coma, death; rapid rehydration also dangerous (brain edema). Data rule: salty scraps = caution, and always-water = hard requirement | https://www.merckvetmanual.com/toxicology/salt-toxicosis/salt-toxicosis-in-animals |
| Moldy grain/food | prohibited | Mycotoxins — swine are "the food animal species most at risk"; aflatoxin, deoxynivalenol (vomitoxin — feed refusal/vomiting), fumonisin, zearalenone (reproductive) | Iowa State: https://www.extension.iastate.edu/grain/topics/MycotoxinsintheGrainMarket.htm ; Penn State DON page: https://extension.psu.edu/from-aflatoxin-to-zearalenone-mycotoxins-you-should-know-deoxynivalenol-don ; SDSU: https://extension.sdstate.edu/can-livestock-utilize-moldy-grain |
| Raw soybeans, cooked beans, bakery waste | ok with ration balancing | Purdue PIH lists as usable; balance ration when substituting | Purdue PIH-07-06-01 |
| Avocado, chocolate | UNVERIFIED (extension) | Widely listed by pig-owner orgs (American Mini Pig Assoc., Open Sanctuary), not confirmed in a university-extension or Merck source this pass — mark rows UNVERIFIED or source-tier "advocacy" | https://opensanctuary.org/things-that-are-toxic-to-pigs/ |

## 5. LICENSE / TERMS

| Source | Copyright status | Data-reuse verdict |
|---|---|---|
| ASPCA (aspca.org) | "©2026 ASPCA. All rights reserved." Terms-of-use page had no explicit data-reuse clause (detail pages 404/sparse) | Facts extractable; no prohibition found. Don't copy prose. |
| Merck Vet Manual | "© 2026 Merck & Co., Inc., Rahway, NJ, USA and its affiliates" — standard all-rights-reserved reference work | Facts (toxin, dose threshold, signs) uncopyrightable; transcribe values with citation, never article text. |
| UF/IFAS Extension blog | © 2026 University of Florida; extension content is public-education material | Facts fine; UF/IFAS generally permits educational use with credit — cite author (Kalyn Waters) + URL. |
| OSU / CSU / Iowa State / Penn State / SDSU / Purdue extension | Standard university copyright; land-grant extension publications are published expressly for public dissemination | Lowest-risk tier; cite factsheet ID (e.g., AFS-8202, PIH-07-06-01). |
| US legal basis | Feist Publications v. Rural Telephone (1991): facts are not copyrightable; only creative selection/arrangement is | Project pattern (own schema, own rows, per-row citation) is lawful for ALL sources above. Avoid reproducing any single source's exact table structure/ordering wholesale to stay clear of compilation copyright. GPLv3 compatibility: no code or licensed text is being incorporated, only cited facts — no license conflict. |

**Flags:** (1) OSU factsheet blocks fetchers (403) — its citrus/rhubarb rows rest on search excerpts; if exact quotes are needed, pull the PDF manually. (2) Citrus-for-chickens is the one genuine extension disagreement — recommend status `caution` with a disagreement note rather than `prohibited`. (3) Pig avocado/chocolate rows are the only UNVERIFIED items — everything else has an authoritative citation.

---

# cmp-0 research — compost-tea parameter priors (agent report, 2026-08-20)

**VERDICT: GREEN for the intended pattern (transcribing published VALUES with citations into a CSV). The NOSB 2004 Compost Tea Task Force Report is a USDA/NOSB federal-advisory publication with no copyright notice — treat as public domain (17 U.S.C. §105); full text retrieved and quotable. All other key sources (Taylor & Francis journals, © 2011 Univ. of Hawaii manual) are conventionally copyrighted, NOT NC-licensed — cite values only, never vendor text/figures/PDFs. No NC-licensed source encountered.**

## 1. Core parameter priors

Scheuerell & Mahaffee 2002, *Compost Sci. Util.* 10(4):313–338, DOI 10.1080/1065657X.2002.10702095 is the foundational review (paywalled; internal tables UNVERIFIED directly — cited via three sources that quote it: NOSB 2004, St. Martin & Brathwaite 2012, UH/SARE manual).

| Parameter | Prior range (honest) | Source |
|---|---|---|
| ACT brew time | **12–24 h typical**; practitioner optimum 12–24 h (Ingham 2005); field practice 12–36 h, up to 48–72 h cold weather | NOSB 2004 p.2; SARE manual p.24; Western SARE ACT Field Guide |
| NCT brew time | **5–8 days, up to 16 days** (Weltzien 1991); "often 1 to 3 weeks" (NOSB); max Botrytis suppression at 7-day brew (Ketterer 1992) | SARE manual p.24; NOSB 2004; St. Martin & Brathwaite 2012 |
| Compost:water (NCT classic) | **1:3 – 1:10 v/v** (Weltzien); suppression drops at 1:50 | St. Martin & Brathwaite 2012, DOI 10.1080/01448765.2012.671516; SARE manual p.22 |
| Compost:water (ACT/vermi tea) | **1:10 – 1:20 v/v recommended**; effective down to 1:100 (linear, Pant 2011); grower practice to 1:125 | SARE manual pp.21–22 (https://www.sare.org/wp-content/uploads/Compost-Tea-Manual.pdf) |
| Dissolved oxygen | **≥6 mg/L, pref ≥8 mg/L** — practitioner guidance, NOT peer-reviewed threshold; NOSB: DO is an uncertain stand-alone pathogen indicator (E. coli facultative) | Western SARE ACT Field Guide (https://www.vineyardteam.org/files/resources/Aerated_Compost_Tea_Western%20SARE.pdf); NOSB p.13 |
| Temperature | NCT: 15–20 °C (Weltzien); ACT: room temp; practitioner 21–27 °C, warmer shortens brew | St. Martin 2012 p.5; SARE manual p.17; ACT Field Guide |
| Additives | Molasses/kelp/humic/fish common; **molasses ≤0.2% avoids pathogen regrowth** | Duffy et al. 2004; ACT Field Guide |
| Use-by after brew | ~4 h after aeration stops (practitioner; refrigeration extends) | SARE manual p.25 |

Honesty note from the literature itself: optimum ratio/brew "varies with brewing process, compost quality and purpose"; ACT-vs-NCT efficacy data thin (most disease-suppression evidence is NCT).

## 2. Food-safety layer (NOSB 2004 + regrowth research)

**NOSB Compost Tea Task Force Report, April 6, 2004** — full text at https://downloads.regulations.gov/FDA-2011-N-0921-0001/attachment_37.pdf (WebFetch 403s; plain curl works; ams.usda.gov archive link dead). Recommendations (verbatim-verified):
1. Potable water for brewing + dilution.
2. Equipment sanitized per 21 CFR 178.1010.
3. NOP §205.203(c)(2)-compliant compost/vermicompost only — incl. 100%-plant feedstocks.
4. Tea WITHOUT additives: unrestricted application.
5. Tea WITH additives: unrestricted only if system pre-tested to EPA recreational water criteria — **E. coli ≤126 CFU/100 mL or enterococci ≤33 CFU/100 mL** (≥2 batches, average); untested additive tea → **90/120-day pre-harvest interval** on food crops.
6. "Compost extract" = held <1 h before use → unrestricted (held >1 h = "tea").
7–8. Raw-manure teas / leachate: soil-only w/ 90/120-day PHI; foliar PROHIBITED.
9. Not allowed on edible sprouts.
Status: no copyright notice; federal advisory record — public domain in practice (minor caveat: non-federal task-force members, so §105 technically may not auto-apply; values unquestionably transcribable).

**Regrowth research** (confirmed via USDA-ARS record + PubMed):
- **Duffy et al. 2004** (*CSU* 12(1):93–96, DOI 10.1080/1065657X.2004.10702163): regrowth correlates with molasses — Salmonella 1 → >1,000 CFU/mL (dairy tea, 1% molasses), → >350,000 CFU/mL (chicken tea) by 72 h; E. coli O157:H7 → ~1,000 CFU/mL. **No regrowth at 0% or 0.2% molasses.**
- **Ingram & Millner 2007** (*J. Food Prot.* 70(4):828–834, PMID 17477249): regrowth NOT brewing-method-specific — driven by nutrient supplements; with supplements **ACT sustained HIGHER pathogens than NCT**. Model risk on ADDITIVES, not aeration.

## 3. N-P-K priors for teas (mg/L, N:P:K) — all is_prior, wide bounds; teas vary wildly

| Tea | N : P : K | Also | Source (via UH CTAHR/SARE manual, © 2011) |
|---|---|---|---|
| NCT, ruminant-manure compost | 315 : 43 : 122 | Ca 23, Mg 13 | Hargreaves 2008 (secondhand — UNVERIFIED vs primary) |
| NCT, MSW compost | 58 : 11 : 188 | Ca 68, Mg 21 | Hargreaves 2008/2009 |
| ACT & NCT, chicken-manure vermicompost | 80 : 16 : 180 | Ca 49, Mg 43; total N 74.9 ± 4.6 mg/L NCT, mostly NO₃-N | Pant et al. 2009 (first-party tables in manual) |
| ACT + additives (ACTME) | higher N/K/Ca/Mg — attributed to the additives themselves | — | Pant et al. 2009 |

## 4. License notes per source

- NOSB 2004 report — public domain; cite regulations.gov URL.
- "Tea Time in the Tropics" — **© 2011 CTAHR Univ. of Hawaii, all rights reserved** (free download ≠ freely licensed): values-with-citation only.
- Taylor & Francis papers (S&M 2002, Duffy 2004, St. Martin 2012) — © T&F, paywalled; values-only; cite the DOI, never link solvita/ResearchGate copies.
- Western SARE ACT Field Guide — no license statement found; values-only. UNVERIFIED license.
- Newer Elsevier reviews (S2352186425001233; S0929139326004129) — 403-blocked, UNVERIFIED content; values-only if used.
