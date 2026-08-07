# Handoff — mesh-app convergence (polari apps × mesh apps)

**Date:** 2026-08-06 · **From:** Fable 5 · **Status:** ⚠ CONCEPT
CAPTURE ONLY — **planning deliberately NOT started.** Dustin: "I am
not sure what is the best approach there so maybe we will be
thinking that through next." The plan gets written *with him*.

Nothing here is a design decision. Where wording is his, it is his.

---

## 1. What Dustin asked for (recorded, near-verbatim)

> "We will want to move on to the mesh-app and figuring out how we
> can use what we built out to then make it so we can have apps be
> distributed across a computer and be able to manage everything as
> though they are mesh-apps.
>
> We will be trying to merge the polari app logic with the mesh app
> logic and try to make a coherent approach to making a more
> flawless approach to using polari to manage the topology
> automatically and enable leveraging and combining different apps
> into polari or isle mesh apps…."

Points as separated for later planning — NOT resolved:

1. **Use what appstore-1/shell-1 built** as the substrate: apps
   distributed across a computer (computers?), managed *as though
   they are mesh-apps*.
2. **Merge polari app logic with mesh app logic** into ONE coherent
   approach — today they are deliberately separate concepts.
3. **Polari manages the topology automatically** — "more flawless";
   today every deploy is knobs-and-suggestions human-invoked
   (`pol topology apply` stays a person's command by explicit
   standing rule — reconciling "automatic" with that rule is a real
   design question, not a detail).
4. **Combine different apps into polari or isle mesh apps** —
   composition of apps, targeting BOTH polari instances and isle
   mesh.

## 2. What already exists (the pieces a merge would draw on)

- **polariapps** — `PolariAppDefinition` (an app = a server-side
  module/pages/nav config), export/apply as credential-free JSON,
  `AppDeploymentPlan` receipts.
- **appstore-1 + shell-1 (built 2026-08-06, live-verified)** —
  downloadable native shells over those apps: enrollment tokens,
  registration documents carrying per-instance reachability
  (`accessibility_scope` local|web|**mesh** — mesh is ALREADY a
  named-but-refused placeholder on InstanceDefinition), multi-
  instance client registries, `polari://` deep links, desktop/
  android/android-vr artifacts in MinIO. See
  memory `polari-app-store.md`.
- **polariPeers** — instance-to-instance mesh: `PeerNode`,
  `PeerAgreement` (admission flow, mesh-convergence phase 1),
  `module_bundle`/`module_exporter`/`module_fetcher` (modules
  travel between instances), `join_flow`, `mesh_facts`.
  ⚠ The app-shell arc explicitly kept shells OUT of this ("NOT
  mesh apps"); this new arc is where the two finally meet — on
  purpose this time.
- **topology module** — `InstanceDefinition`/`ModuleAssignment`/
  `ModuleDependencyEdge`, `provider_registry` (module delegation
  resolves providers from rows), portable topology packages,
  `pol topology assign` + derived `POLARI_MODULES` (mod-env-3),
  `pol swarm deploy` re-render. `OrchestrationTarget` 'isle' =
  named-but-unavailable, exactly parallel to accessibility 'mesh'.
- **Graceful mobility (gm)** — blue-green module moves as data.
- **xsim** — cross-instance simulation coupling.
- ⛔ **isle-mesh networking lives on isle-core's own Claude**
  (standing rule since 2026-06-20): do NOT rebuild isle networking
  here. The seam is presumably: polari declares/consumes, isle-core
  transports.

## 3. Ambiguities to resolve WITH Dustin (not guessed here)

- What IS a "mesh-app" to him, concretely? (A PolariAppDefinition
  whose modules span instances? A shell that roams? A bundle that
  installs itself onto whatever node is nearby?)
- "distributed across a computer" — one machine, many instances?
  or across the machine fleet (pol-core / isle-core / econ-core)?
- "manage the topology automatically" vs the standing
  knobs-and-suggestions + deploys-stay-human rules — does he want
  auto-EXECUTION, or auto-PLANNING with one-command apply?
- Where does the App Store sit in a mesh world — per-instance
  stores, or one mesh-wide catalog with instance-local artifacts?
- Do the two placeholders ('mesh' accessibility scope, 'isle'
  orchestration target) become real in this arc, and which side
  (polari or isle-core) owns each?

## 4. State at handoff

- App Store arc COMPLETE + live on prf-a (all four platforms
  available; full download→register→probe→auto-redeem loop proven).
  Linux desktop manual check + push = Dustin. iOS: sources only, no
  Mac available. VR APK: no headset attached for on-device verify.
- Everything committed innermost-first, NOTHING pushed;
  `polari-app-shell/` awaits remote + .gitmodules.
- Staging cert leaves renewed 2026-08-06; they are 30-day — recur
  ~Sep 5.
