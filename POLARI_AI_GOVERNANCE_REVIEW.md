# Polari AI Governance and Deployment Architecture — Critical Review

**Date:** 2026-07-19
**Reviewer:** Claude Fable 5 (Claude Code session)
**Status:** Initial review — for Dustin's evaluation. Nothing here is legal advice; policy
readings are grounded in Anthropic's Commercial Terms §D.4 / §B and the Usage Policy as
fetched 2026-07-19, with uncertain items explicitly flagged for written clarification.

---

## 1. Executive judgment

The architecture is fundamentally sound and, importantly, **most of it already exists in
Polari** in embryonic form (module registry, admission advisor, topology-as-data, the
no-code engine, CRUDE typed APIs). The proposal's core instincts — typed proposals,
deterministic validation, transactional execution, provenance, verifier-derived training
labels — are the right ones and match how the strongest agent systems are being built.

Four findings dominate this review:

1. **There is a structural contradiction in the training-corpus plan.** The corpus is
   defined to include "Polari's own source code and documentation," while Fable is
   simultaneously permitted to "generate source code" that lands in that same codebase.
   Unless Fable-authored code is provenance-tagged and excluded from the corpus (or
   Anthropic grants written authorization), the corpus silently contains model outputs and
   the "no distillation" boundary collapses. This is the single most important fix.

2. **The plan uses Fable most where policy is most restrictive, and least where Fable is
   safest.** "Preference judgments" and "evaluating another model" are the two items most
   likely to constitute prohibited distillation if any result feeds training; meanwhile the
   unambiguously-permitted uses (building the harness, validators, and generators) cover
   ~90% of the actual engineering work. The plan survives almost intact by moving two
   items out of the training loop.

3. **The safety pipeline is correct but incomplete.** It validates *proposals* but does not
   yet treat *observations* as untrusted (the prompt-injection surface of every agent
   system), does not attenuate authority at session-mint time, has no independent monitor
   outside the proposal path, and lets the roadmap reach "increasingly autonomous topology
   management" before an evaluation harness exists. Several specific operations must never
   be delegated to an LLM at all (§5.4).

4. **The verifiable-label corpus cannot produce a Governor.** Compilers, solvers, and tests
   generate excellent training signal for the Systems Engineer / Scientific / Data roles —
   narrow, checkable tasks. Open-ended planning, risk classification, and intent
   interpretation have no deterministic verifier. The open-weight model will plateau as a
   competent tool-caller and a weak planner. Plan for the Governor role to remain on a
   frontier model (or humans) far longer than the roadmap implies, and don't let the
   sovereignty instinct assign the *hardest* role to the *weakest* model.

Verdict: **proceed**, with (a) the provenance firewall of §4 made non-negotiable before any
training run, (b) the two Anthropic clarification letters of §8 sent before writing any
Fable-in-the-training-loop code, and (c) the roadmap resequencing of §6.

---

## 2. Policy compatibility matrix

Grounding (fetched 2026-07-19):

- **Commercial Terms §D.4:** Customer may not "access the Services to build a competing
  product or service, including to train competing AI models or resell the Services except
  as expressly approved by Anthropic."
- **Commercial Terms §B:** Customer "owns its Outputs"; Anthropic assigns its right, title
  and interest in Outputs to Customer, *subject to compliance with the Terms*.
- **Usage Policy:** prohibits "utilization of inputs and outputs to train an AI model
  (e.g., 'model scraping' or 'model distillation') **without prior authorization from
  Anthropic**" — note the phrase implies an authorization path exists.

A key legal structure to internalize: **owning the Outputs does not neutralize the use
restriction.** §B is an IP assignment; §D.4 is a contractual conduct restriction on you.
You can own a piece of Fable-written code outright and still be contractually barred from
using it as training data for a competing model. These are independent axes.

| # | Intended use | Reading | Rationale |
|---|---|---|---|
| 1 | Fable designs/builds Polari's agent infrastructure (schemas, validators, executors, harnesses) | ✅ **Clearly allowed** | Ordinary software development. This is the product Claude Code exists for. |
| 2 | Fable *operates* Polari at runtime through typed tools (deploy modules, run workflows, manage topology) | ✅ **Allowed, with Usage-Policy caveats** | Agentic use is explicitly contemplated. Caveats: human oversight for consequential actions; no operation of safety-critical physical interlocks (§5.4); the Usage Policy's critical-infrastructure and high-risk-domain clauses don't apply to a private research framework, but physical-hardware actions (laser CNC, printers) warrant human-in-the-loop as a matter of the policy's spirit and your own safety-MCU design. |
| 3 | Fable generates source code committed to Polari | ✅ **Clearly allowed** | You own the Outputs (§B). |
| 4 | Fable constructs scientific workflows (FEM/DFT/MD/PSPP configs) | ✅ **Clearly allowed** | Same as 3. Note Fable-specific safeguards may refuse dual-use materials-science edges (energetic materials, certain bio-adjacent chemistry) — expect occasional `refusal` stop reasons and design the harness to degrade gracefully, not to route around the classifier (routing-around is itself a policy problem). |
| 5 | Publishing Fable-generated code/schemas/docs/critiques in public OSS repos | ✅ **Allowed** | You own the Outputs and may license them (all 8 Polari repos are already public). Two caveats: (a) *you* re-ingesting that public repo into your own training corpus is still *you* using Outputs to train — publication does not launder the restriction; (b) third parties scraping your repo are outside your contract with Anthropic, but deliberately structuring publication so "a third party" (or a future you) trains on it would be bad-faith circumvention. |
| 6 | Fable evaluates the open-weight model (benchmarking, error analysis) — results **never used as training signal** | ⚠️ **Questionable — likely tolerated, get it in writing** | Pure measurement isn't training. But the line blurs fast: if Fable's evaluations *select checkpoints*, *filter training data*, or *drive curriculum*, Fable's judgment is shaping the competing model — functionally distillation-adjacent. The Commercial Terms don't carve out evaluation; the safest reading is eval-for-human-consumption is fine, eval-in-the-training-loop is not. Ask (Q3, §8). |
| 7 | Fable produces preference judgments (rankings, critiques used for RLHF/DPO/rejection sampling) | ❌ **Likely prohibited without authorization** | Preference labels used as a reward/selection signal are the textbook mechanism of preference distillation. This is squarely "utilization of outputs to train an AI model." Do not build this without written authorization. |
| 8 | Any Fable-derived material in the open-weight training corpus (code, docs, critiques, synthetic exemplars, few-shot seeds) | ❌ **Prohibited without authorization** — and currently *implicit* in your corpus plan | See finding 1. "Polari's own source code and documentation" will contain Fable outputs unless you build the provenance firewall (§4.2). Also covers subtler leaks: Fable-written docstrings, Fable-authored gold solutions used as few-shot seeds in generators, Fable-rewritten specs. |
| 9 | Fable designs dataset-generation machinery, validators, eval frameworks (but not labels) | ✅ **Allowed — with a flagged second-order concern** | The generator is code (an Output you own, used as software, not as training data); the *labels* come from compilers/solvers. Legally this looks clean. Flag: Fable's design taste still shapes the task distribution and rubrics — a second-order influence that is almost certainly fine under the letter of the terms, but disclose it when you ask Anthropic Q4 so the authorization covers reality. |
| 10 | Is a 14–20B Polari-operations model a "competing product" at all? | ⚠️ **Genuinely uncertain — the threshold question** | A narrow domain model that only drives Polari workflows arguably competes with nothing Anthropic sells; a general-purpose 14B coding/agent model plainly does. Your model sits in between (codebase assistance + agentic operation is close to Claude Code's territory). §D.4's "including to train competing AI models" reads broadly. This is Q1 in §8 — the answer determines how much of the rest of the matrix even binds you. |
| 11 | Written exception / partnership agreement | **Recommended regardless** | The Usage Policy's "without prior authorization" language means authorization is a real, contemplated path. Even if you never use Fable labels, a short written acknowledgment that your verifier-label pipeline + Fable-as-toolsmith pattern is compliant removes the tail risk from your whole roadmap. |

**Items requiring direct clarification from Anthropic:** rows 6, 7, 8, 10 — drafted
verbatim in §8. Do not treat any reading above as settled; the Terms give Anthropic
interpretation latitude, and the cost of asking is one email.

---

## 3. Recommended reference architecture

### 3.1 Core principle: roles are policy objects, models are plumbing

Every deployment strategy you listed (one frontier model, one local 14B, adapters,
specialist fleet, hybrid escalation) is expressible without redesign **iff** Polari never
binds a role to a model anywhere except one late-bound routing table. Concretely:

```
Role (persistent, in object tree)          Session (ephemeral)             