# AI Tool Linkages — plan (ai-0..ai-5)

**Date:** 2026-08-15 · **Status: ARC COMPLETE — ai-0..ai-5 BUILT +
DEPLOYED 2026-08-15/16. ai-5 made the intermediary tiles genuinely
installable: the store detail pane RUNS the binding flow (select →
human-typed credential → validate, per-step results, readiness
re-join; privacy recommendation worn in the flow); wire live-proven
via the built-in provider. Pending only Dustin's proofs
(TESTING_OWED §00). Earlier phases below.**
Phases ai-0..ai-4: BUILT + DEPLOYED
2026-08-15 (late session, Dustin's go: "we are doing some work on
the ai configuration, self-hosting, and binding" → "move on to 4")
— backend + store UI + voice on `dev-ai-1` (framework, angular);
selftests appstore 67/67, islemesh 95/95, engines 18/18,
polariapps 57/57; live-proven on staging (ai-tools API, catalog AI
section, /engines/reasoning, /ai/voice honest refusal, the two
linkage app rows). ai-4 delivered /ai/voice (provider-backed
STT/TTS, sovereignty stated) + panel voice path + linkage apps
(meetings-stt deferred: collab transcription seam unbuilt).
REMAINING: ai-5 (intermediary apps polish), Dustin's proofs in
TESTING_OWED §00.**
Original status: PLANNING ONLY (Dustin: "do not
build the first slice just make a plan for the next arc").
Grounded in a read-only survey of the reasoning seam, the store
machinery, and the LocalAI evaluation — nothing here is guessed.

**Dustin's brief, verbatim intent:** "build different categories
and linkages for ai tools since we may want different linkages in
different places. We would then build out apps for those different
kinds of linkages. Like making claude binding an isle-app, making
the localAI isle-apps, and making it clear what bindings different
AIs can feasibly map to and interact with capably. For apps like
claude or codex, they would simply be intermediaries for talking to
and binding to a remote server through the internet. For others
they would be locally hosted. We would want a dedicated section in
the app store for this."

## Ground truth (surveyed 2026-08-15)

- **The reasoning seam already exists and is provider-agnostic**:
  `polariApiServer/reasoning_provider.py` — providers `null`
  (deterministic no-LLM fallback), `anthropic`, `openai`,
  `openai_compatible` (takes `base_url`, key optional — a LocalAI
  container plugs in as CONFIG, not code; tool-calling for the
  assistant's gated proposals rides the same wire).
- **Managed config + API exist**: `reasoning_config.py`
  (PROVIDER_REGISTRY with per-provider readiness: sdk installed /
  credential / base_url; JSON files git-ignored, secrets chmod 600)
  + `providersAPI.py` (`GET /ai/providers` status;
  `POST {action: select | set_auth | validate}` — set_auth never
  echoes the secret).
- **Store machinery from the sep arc is the chassis**:
  IsleCatalogEntry carries `category` + `provides_engine`;
  `_BINDERS` wires engines to consumer config on isle deploy
  (`_bind_odoo` precedent); derived options (sep-3) prove
  rows-free store sections; ENGINES registry + `/engines/:kind`
  data pages (sep-4); AppEdgeBehavior references (sep-5).
- **LocalAI evaluated GREEN** (LOCALAI_3D_BACKENDS_EVALUATION.md
  §4b): MIT, OpenAI/Anthropic-compat server, CPU-ok, air-gapped;
  fork pin dausume/LocalAI + 14 backend pins.
- **Voice today is NOT sovereign**: the assistant panel uses
  browser Web Speech APIs (Chrome STT is cloud-backed).

## ✅ DECIDED (from Dustin's brief)

| # | Decision |
|---|---|
| 1 | **AI tools are first-class store citizens** in a DEDICATED app-store section — never buried under generic apps |
| 2 | **Two hosting kinds, stated on every tile**: `remote-intermediary` (claude, codex/openai — thin bindings to a remote server over the internet) and `local-hosted` (LocalAI + its backend family). The built-in `null` fallback rides along for honesty (always available, no LLM) |
| 3 | **Linkages are a VOCABULARY, not prose**: the places an AI can plug into Polari are named kinds (reasoning-chat, tool-calling, stt, tts, embeddings, vision, 3d-reconstruction, realtime-voice), each naming its CONSUMER (which Polari seam/knob it wires) |
| 4 | **Every tool declares which linkages it can feasibly serve, and how capably** — per-linkage status `proven` (wired today) vs `feasible` (wire exists, unproven), joined LIVE with readiness from PROVIDER_REGISTRY (sdk/credential/base_url probes). Feasibility claims are honest, never implied working |
| 5 | **Apps per linkage kind**: each linkage that matters grows an APP (the sep-3/sep-4 pattern — tiles, data pages, launchers), so "the assistant's reasoning binding" or "meetings transcription" is a visitable, configurable thing |
| 6 | **Sovereignty is a first-class fact**: every tool tile states `internet_required` and `data_leaves_isle`; remote intermediaries recommend the privacy-filter gate upstream (small-business empowerment includes not leaking their data) |

## Phases

- **ai-0 — the object model.** `AiToolDefinition` rows (appstore
  module, next to AppEdgeBehavior): name, title, hosting
  (`remote-intermediary|local-hosted|built-in`), api_family
  (`anthropic|openai|openai-compatible|none`), provider_name
  (PROVIDER_REGISTRY mapping, '' if not a reasoning provider),
  linkages_json (kind + status + note per linkage),
  internet_required, data_leaves_isle, source_ref (API domain or
  container image). AI_LINKAGES vocabulary as code constant, each
  kind naming its consumer seam + knob. Seeds: `null` (built-in),
  `claude` (remote, anthropic — reasoning-chat/tool-calling proven,
  vision feasible), `openai` (remote, covers Codex — same proven
  pair, stt/tts/embeddings feasible), `localai` (local,
  openai-compatible — proven pair via wire, stt/tts/embeddings/
  vision feasible, 3d-reconstruction via the sibling ports).
  Seeded via BOTH passes (legacy for prf-a, AppStoreSeed upsert).
- **ai-1 — the honest readiness API.**
  `GET /api/appstore/ai-tools`: tools + the linkage vocabulary +
  per-tool LIVE readiness joined from reasoning_config
  (sdk_installed / credential present / base_url set / validate
  probe) — "feasibly map to and interact with capably" as data.
- **ai-2 — the store section.** islemesh catalog derives `ai-tool`
  entries (category `ai`, the sep-3 derived-options pattern — rows
  stay in appstore, the section derives). Install plans per
  hosting: built-in → nothing to do; remote-intermediary → the
  /ai/providers select + set_auth actions (credential entered by
  the human, never stored in git); local-hosted → `isle app deploy
  localai --image ... --engine reasoning`. Store UI: dedicated
  section + hosting/ready/sovereignty badges + a linkage table in
  the detail pane.
- **ai-3 — the reasoning binder + engine page.**
  `_BINDERS['reasoning']` → `reasoning_config.set_active(
  'openai_compatible', {'base_url': <url>/v1})` (the _bind_odoo
  shape) so deploying LocalAI anywhere on the isle auto-wires every
  instance's assistant; ENGINES registry entry `reasoning` so
  `/engines/reasoning` shows the active provider, the readiness
  ladder, and usage (meter the reasoning calls the same way the
  msci/cad seams meter).
- **ai-4 — linkage apps.** Per decision 5: app rows for the
  linkages that matter (assistant-reasoning, meetings-stt, voice)
  with engine_page-style data pages; sep-3 launchers come free.
  Voice sovereignty lands here: the assistant panel gains a
  provider-backed STT/TTS path (LocalAI /v1/audio/*) with the
  browser Web Speech path as the stated fallback.
- **ai-5 — the intermediary apps.** Claude/Codex as installable
  isle-apps: thin tiles whose "install" is the ai-2 binding flow +
  the privacy-filter recommendation; TESTING_OWED gets Dustin's
  pass (credentials are his).

## Boundaries

- Ours: framework (appstore rows/API, islemesh projection +
  binder, ENGINES entry), angular (store section, engine page
  reuse, ai-4 voice path).
- Dustin's: credentials (set_auth is his step), which remote
  intermediaries to enable at all, model choices per box.
- isle-core's: nothing until ai-2's local-hosted install plan needs
  `isle app deploy` verified for the LocalAI image (request-doc
  note when we get there).

## Open questions for Dustin

1. Should remote intermediaries be FORCED through privacy-filter
   once it's hosted (hard gate), or is the recommendation badge
   enough (knob-and-suggestion discipline says badge + knob)?
2. Codex/OpenAI as ONE tool row (`openai`) or split rows per
   product surface? (Plan assumes one row; both ride the same
   provider.)
3. Does the `reasoning` engine meter conversation content
   NEVER (counts/bytes/latency only, like msci/cad) — assumed yes?

## Grounding index

- `polariApiServer/reasoning_provider.py` (providers, tool loop),
  `reasoning_config.py` (registry, readiness, set_active),
  `providersAPI.py` (/ai/providers), `aiChatAPI.py`, `ai_tools.py`
- `modules/appstore/{appstore_basis,appstore_seed,appstore_api}.py`
  (AppEdgeBehavior precedent, seeds via both passes)
- `modules/islemesh/{islemesh_catalog,islemesh_engines,
  islemesh_api}.py` (derived options, _BINDERS, catalog)
- `topology/engines_api.py` (ENGINES registry, engine pages)
- angular: `components/islemesh/isle-store.component.*`,
  `components/ai-assistant/ai-assistant-panel.component.ts`
  (Web Speech seams at lines ~205/298),
  `services/ai-assistant/ai-assistant.service.ts`
- LOCALAI_3D_BACKENDS_EVALUATION.md (licenses, fork pins)
