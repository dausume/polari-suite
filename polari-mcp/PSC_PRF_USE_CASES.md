# Making PSC + PRF approachable — AI-assisted use cases

The MCP server + gated capability + provenance log turn Polari's political
scorecard (PSC) and research framework (PRF) into systems an **average person**
can understand, navigate, and safely contribute to. The AI is the translator
between plain language ("I care about fair wages") and the system's structure
(`ScoreTerm minimum-wage`, `ScoreSubject policy-fair-wage-act`, its `GovSource`
evidence). Every capability below is grounded in objects that already exist on
the node; the pattern is always **progressive disclosure → traceable evidence →
gated contribution**.

## Political scorecard — for the citizen

1. **"Explain this score to me."** Plain-language walkthrough of how a subject
   was scored: which terms and contexts, which assertions, and the source chain
   behind each. Tools: `polari_psc_scoring` + `polari_psc_sources`. Turns a
   number into an argument a person can evaluate.
2. **"Start from what I care about."** Guided intake: the user names issues
   (housing, wages, policing); the AI maps them to real terms/subjects via
   `polari_psc_search` and shows the relevant scores and who stands where.
3. **"Show me the evidence."** For any score or claim, surface the
   `GovSource` → `SourceRetrieval` → `FactualClaim` chain so a skeptic can trace
   it to primary sources. Distrust of a political tool is answered with
   provenance, not assertions.
4. **"Check this claim against the record."** The user says "I read that this
   bill does X" → `polari_propose_pull_and_assert` proposes a `FactualClaim`
   tying a source to the policy/subject, gated and logged. Citizen fact-checking
   without the risk of editing live data.
5. **"Compare on my terms."** Side-by-side of two policies/candidates on only the
   terms the user chose — not a firehose.
6. **"What's the political context of my area?"** Map-driven: `polari_psc_maps`
   (`ZoneDefinition`/`SiteDefinition`) → local scores and sites, so context is
   grounded in place.
7. **"Where do reasonable people disagree, and why?"** The judicial/
   decision-procedure layer (`LogicForkCriterion`, `WorldviewElection`,
   `DecisionProcedureEdge`) rendered as a *feature*: the assistant explains the
   forks instead of hiding them, making disagreement legible.
8. **Safe participation.** A citizen proposes a score assertion or a new source;
   it is captured as a gated proposal with provenance and reviewed, never
   auto-applied. Crowd input becomes possible *because* the gate makes it safe.

## Research framework (PRF) — for the non-expert

1. **"Run this and tell me what happened."** The AI sets up a simulation (gated),
   steps it (`polari_propose_sim_step`), and narrates the state changes in plain
   language (`polari_sim_state` before/after). A layperson watches a system
   evolve without reading solver output.
2. **No-code by conversation.** "Make a display that reacts to Y" → the assistant
   proposes the display edit + event binding; the user confirms. Building
   reactive UI without touching the D3 editor.
3. **"What can this node do right now?"** `polari_topology` +
   `polari_list_modules` → a plain-language capability tour for someone who just
   opened the app.
4. **"What is this material / object?"** Natural-language query over the science
   objects → a readable summary instead of a class dump.
5. **Reproducibility for everyone.** Every AI action is one JSON line in the
   provenance log: "show me exactly what the assistant did" is a real answer, not
   a shrug — the same rigor a researcher needs and a citizen deserves.
6. **Voice + VR walkthroughs.** In the WebXR surface the assistant narrates the
   scene ("what am I looking at?") and takes voice commands — the complex 3D/
   no-code environment becomes navigable without a keyboard or prior training.

## The cross-cutting patterns (why this works for non-experts)

- **Progressive disclosure**: overview → search → detail → act. Nobody is dropped
  into raw complexity; each step is a plain-language rung.
- **Plain-language ↔ structure translation**: the AI maps what a person says to
  ids/classes and back, so users never learn the schema.
- **Trust through provenance**: every score, claim, and AI action is traceable.
  For a political tool this is the whole ballgame.
- **Visible guardrails**: the authority levels make it obvious what the AI can do
  alone vs. what needs a human (e.g. connecting storage, or anything level ≥ 4) —
  legibility that builds trust rather than eroding it.
- **Gated participation**: laypeople can contribute (scores, sources,
  refinements) without breaking anything — the review gate is what makes broad,
  non-expert participation viable.

## What's needed to make these fully real

- A real reasoning provider (`POLARI_REASONING_PROVIDER=anthropic` + credential)
  for the natural-language translation; the plumbing already runs node-aware
  without one.
- Data in the currently-empty PSC classes (`PolicyDraft`, `CourtCase`,
  `LegislationRecord`, `MapPointDefinition`) for the policy/judicial/map flows.
- Wiring the custom scoring sub-routes (`/api/scoring/*`, `/api/zones/*`) into
  dedicated tools where CRUDE reads aren't enough (e.g. computed scores).
- PSC frontend surfacing (the scorecard's own Angular app) + the in-app assistant
  panel, plus a browser/headset pass.
