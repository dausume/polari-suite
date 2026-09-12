# Modules and apps by every route

Once Polari is running, a module or app can be set up four ways. They all end in the same place, a row in the registrar saying the module is online, and `pol prod verify` proves all four against a live instance.

## Console

`pol project deploy --api https://api.prf.example.org` from a module's own project fetches it from its repository and admits it. `pol modules` manages the local tree. Underneath is one API call, `POST /modules/<m>/fetch-admit`, which clones the module from its `polari-module-*` repository onto the instance's data volume and admits it from its manifest, dependencies first.

## Apps

The App Store and the Download page. `/downloads/apps` lists what can be installed; the store installs with a click; a module's deb is built on demand from the fetched repository for desktop and isle installs, online or offline flavor.

## Interfaces

Every module's pages are rows, seeded on admission, and the module-health display shows every module's state and the reason. A module can be admitted, verified or put away from there.

## Topology

The durable truth of which module runs where is a `ModuleAssignment` row. `pol topology assign <module> <instance>` writes one; `POST /api/topology/assign` is the same call; the topology displays show and propose them; and the deployment derives each instance's module list from those rows, never the other way round.

## Proving it

```
pol prod verify
```

runs against the deployed instance: API alive, registrar online, an optional module fetched from GitHub and admitted through the console route, listed and buildable through the apps route, its display rows present, and a topology assignment written and read back through the CLI. Each check prints pass or fail with the reason.

## Core and optional

Modules are tiered. Core modules make Polari a networking and app system and are in every image. Optional modules are baked into the all-official image and fetched on admission with the core image. The register carries the tier, and `pol modules list` shows it.
