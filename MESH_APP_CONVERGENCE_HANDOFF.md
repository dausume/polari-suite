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

## 2b. Dustin's follow-up answers (2026-08-06, recorded — these
## PRE-RESOLVE part of §3)

> "they can choose between auto or manual, and we will want to
> leverage it. We also previously defined everything assuming
> docker compose based apps. However we likely want to upgrade
> that so that the apps can effectively operate as though they are
> docker swarm apps. Or they are shell apps, basically allowing
> you to access the apps from another computer via web despite it
> actually being installed elsewhere."

As separated for planning:

1. **Auto vs manual is a CHOICE (a knob), not a doctrine** — the
   operator picks per-something (per app? per topology? to be
   pinned down), "and we will want to leverage it" — i.e. auto
   mode is expected to do real work, not be decorative. This
   dissolves the §3 tension: knobs-and-suggestions survives as the
   DEFAULT (manual), auto is an explicit opt-in knob.
2. **Upgrade ISLE-MESH's existing converter tool** (corrected by
   Dustin 2026-08-06): "isle mesh has a tool to automate converting
   compose into being a mesh app, we will want to upgrade that
   capability in order to automate them into becoming docker swarm
   capable apps, along with integrating together the mesh app
   automation capabilities with polari capabilities." So the work
   is TWO-sided:
   (a) the compose→mesh-app converter that ALREADY EXISTS on the
       isle-mesh side gets upgraded to emit swarm-capable apps;
   (b) that mesh-app automation gets integrated with polari's
       capabilities (topology rows, app definitions, the store).
   **THE GOAL (Dustin, verbatim): "our goal is to combine the two
   systems meaningfully not just upgrade one or the other."** So
   frame every design choice as convergence — one coherent
   app-automation system with polari and isle-mesh as its two
   halves — not as patches to either side. The converter upgrade
   and the polari integration are means; the combined system is
   the deliverable.
   ⚠ The converter presumably lives in isle-core's repos, and
   isle-core has its OWN Claude holding isle-mesh memories (rule
   since 2026-06-20) — the next session must LOCATE the tool
   first (isle-core over SSH, or ask Dustin where it lives) rather
   than assume its shape, and decide which side each change lands
   on. Note polari's own stackify.py (`pol swarm render`) does a
   compose→swarm-stack transform for INSTANCES — related but not
   the same tool; the combined system is where those two
   transforms likely become one model.
3. **OR shell apps as the other realization**: an app stays
   installed where it is, and the app-shell machinery
   (appstore-1/shell-1: registration, reachability, multi-instance
   registry) gives access "from another computer via web despite
   it actually being installed elsewhere". So a mesh-app has (at
   least) two delivery modes — MOVE the app (swarm placement) or
   REACH the app (shell access) — and the model should treat them
   as two answers to one question.

## 3. Ambiguities STILL open (after §2b; resolve with him)

- ~~auto vs manual~~ → RESOLVED as a knob (§2b.1). Remaining: the
  knob's GRAIN (per app? per topology? per move-class?) and what
  auto is allowed to touch (module assignment only? container
  deploys? cert/env renders?).
- What IS a "mesh-app" concretely — given §2b it looks like: one
  app definition + a per-deployment CHOICE of realization
  (swarm-distributed vs shell-reached vs both). Confirm that
  framing before modeling it.
- "distributed across a computer" — one machine, many instances?
  or the fleet (pol-core / isle-core / econ-core)? §2b.2's swarm
  wording suggests the fleet; confirm.
- Where does the App Store sit — per-instance stores, or one
  mesh-wide catalog with instance-local artifacts?
- Do the two placeholders ('mesh' accessibility scope, 'isle'
  orchestration target) become real in this arc, and which side
  (polari or isle-core) owns each?
- App-layer swarm: does a module/app become a swarm SERVICE of its
  own, or stay inside the instance containers with swarm placing
  the instances (today's model)? This is the biggest architecture
  fork §2b.2 opens.

## 4. State at handoff

- App Store arc COMPLETE + live on prf-a (all four platforms
  available; full download→register→probe→auto-redeem loop proven).
  Linux desktop manual check + push = Dustin. iOS: sources only, no
  Mac available. VR APK: no headset attached for on-device verify.
- Everything committed innermost-first, NOTHING pushed;
  `polari-app-shell/` awaits remote + .gitmodules.
- Staging cert leaves renewed 2026-08-06; they are 30-day — recur
  ~Sep 5.
