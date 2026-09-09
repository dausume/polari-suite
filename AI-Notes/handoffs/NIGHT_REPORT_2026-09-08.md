# Night report 2026-09-08 → 09 — hardware apps, the hardware map, the Voron, Kiri:Moto, suite apps

Everything below is BUILT, proven in test-build boots, committed on dev (not
pushed). Read order: this file → `AI-Notes/designs/STANDARD_POLARI_APP.md`
§9 → `AI-Notes/plans/HARDWARE_APPS_PLAN.md` §7 →
`AI-Notes/evaluations/PRINTER_STACK_GATE.md`.

## What exists now (modules, all on the standard layout)
| module | kind | what | proof |
|---|---|---|---|
| hardwareapps | library | HardwareAppDefinition/State; domain XML + UCI renderers; provisioner hook; `/api/hardwareapps[/render/<n>]` | 10/10 |
| isle_relay | hardware-app | relay guest (VLAN 30, AP, forwards into the isle, bearer 4242) | 6/6 |
| isle_guestnet | hardware-app | guest-only WiFi guest (VLAN 20, REJECT, isolation, exposures as rows) | 6/6 |
| hwmap | polari-app | the hardware map: scanner, mapping rules, rows, ingest/query, `pol hwmap` | 15/15; real scans of all 3 boxes |
| voron | hardware-app | Klipper+Moonraker+Mainsail in a Debian guest; sim mode; pinned upstreams | 16/16 |
| kirimoto | isle-app | Kiri:Moto container from pinned MIT commit; profiles; store row | 5/5 |
| suiteapps | library | suite-app kind: parts, contracts, placement | 9/9 |
| printing_suite | suite-app | the production printing suite + its contract rows | 8/8 |
| reticulum | hardware-extension-app | reclassified: extends isle-relay | — |

Test-build boot with all of them + islemesh/mathshapes/casting/materials_science:
health 50 s, 0 tracebacks; `/api/suiteapps/printing-production` placed 6/8
parts (printer + relay: needs-hardware-tier — pol-core has no /dev/kvm);
`pol hwmap push` from this box → 18 ports, 4 mappable; pages seeded:
hardware-apps, hardware-map, voron, kirimoto, suite-apps, printing-suite.

## Real hardware facts (pol hwmap over ssh, fixtures in modules/hwmap/custom/)
- pol-core: no cpu-virt flags, no /dev/kvm, no IOMMU → not a hardware-tier
  device; 2 CP210x serial bridges (printer-board shaped), 1 MediaTek USB WiFi.
- isle-core: cpu-virt + kvm + libvirt + 10 IOMMU groups → HARDWARE-TIER READY;
  8 mappable (usb hostdev + 3 pci vfio); its WiFi/BT are a PCI card + a BT
  function (not a USB WiFi adapter).
- econ-core: cpu-virt + kvm, NO libvirt, 17 IOMMU groups → one apt install
  from the tier.

## Decisions for you
- D6 the name "suite app" (alternatives in design §9.6).
- D7 the first extension apps to build (printcam on voron; arch-relay on
  isle-relay) — design §9.5.
- D8 whether Kiri:Moto's Moonraker upload (browser → `/server/files/upload`)
  is the hand-off, or the SliceJob → GcodeArtifact automation through the
  object store.
- The Voron guest image pin (`debian-12-genericcloud-amd64.qcow2` raw sha)
  and the printer boards' `serial_by_id` once a board is plugged into
  isle-core.

## What is NOT done
- The isle side: `isle vm` verbs (define/start/status/extend/attach),
  `agent.tier=hardware`, state pushes — requested in NOTES-FROM-POL-CORE.md.
- The Kiri:Moto image BUILT from the pinned commit (`polari/kirimoto:ff7692241c`,
  2.09 GB — the upstream Dockerfile mirrored; one git+ssh dependency rewritten
  to https at build time) and SERVES: `GET /kiri/` → HTTP 200 from the container.
  The Voron guest image is not fetched (deploy-time pin).
- No physics simulation of printing exists open-source; the ladder and the
  waxprint rung are in the gate.
