# Setting up the AI reasoning provider for a Polari instance

The in-app AI assistant, the `/ai/chat` endpoint, and the MCP-driven capability
all run on a **reasoning provider** you choose per instance. Out of the box an
instance runs the **`null`** provider — a deterministic, node-aware responder
that needs no key — so everything works immediately. This guide shows how to
switch a Polari instance to a real model (Claude, OpenAI, or any local /
OpenAI-compatible endpoint) and how credentials are handled safely.

Related: the machine-readable standard is `ai_conventions.json`; the code is
`polariApiServer/reasoning_config.py` (registry + detection) and
`reasoning_provider.py` (the providers).

---

## The model in one picture

```
choose provider ──▶ install its SDK ──▶ enter its secret (human, once)
        │                                        │
        └────────────▶ select + validate ◀───────┘
                            │
                    /ai/chat + assistant + MCP now use it
```

Three facts to keep in mind:

- **Detection is automatic.** Ask the instance what each provider still needs
  (`GET /ai/providers`) — it tells you exactly (`pip install …`, set a key, set a
  base_url).
- **Secrets are entered by a human, never by the AI.** The AI may read status,
  *propose* a selection, and validate — it must not set credentials. A secret in
  an AI tool call would land in the audit log. You enter it directly (below).
- **Secrets stay private.** They're stored in a `chmod 600`, git-ignored file
  under `data/` (or read from the environment) and are never returned by any
  read — status only ever shows a `has_credential` boolean.

---

## 0. Prerequisites

- A running Polari node. Bare-metal dev serves the API at `http://localhost:3000`;
  the suite/proxy mode serves at `https://localhost:2096`. Substitute your base
  URL for `$BASE` below.
- Shell access to the machine running the node (for `pip install` and for
  entering the secret).

```bash
BASE=http://localhost:3000     # or https://localhost:2096 behind the proxy
```

---

## 1. See what's available

```bash
curl -s "$BASE/ai/providers" | python3 -m json.tool
```

You'll get every provider with `ready` and a `needs` list, e.g.:

```json
{
  "active": "null",
  "providers": [
    { "name": "null",      "ready": true,  "needs": [] },
    { "name": "anthropic", "ready": false, "needs": ["pip install anthropic"] },
    { "name": "openai",    "ready": false, "needs": ["pip install openai", "set OPENAI_API_KEY (or enter it via the backend)"] },
    { "name": "openai_compatible", "ready": false, "needs": ["pip install openai", "set base_url"] }
  ]
}
```

Work down the `needs` list for the provider you want.

---

## 2. Pick a provider and set it up

### A) Claude (Anthropic) — recommended default for a real model

```bash
# 1. SDK (into the same Python env the node runs in)
python3 -m pip install --user anthropic

# 2. Credential — either an env var the node inherits ...
export ANTHROPIC_API_KEY=sk-ant-...
#    ... or enter it into the instance's secret store (human action, not the AI):
curl -s -X POST "$BASE/ai/providers" -H 'Content-Type: application/json' \
  -d '{"action":"set_auth","provider":"anthropic","secret":"sk-ant-..."}'

# 3. Select it (optionally pin a model)
curl -s -X POST "$BASE/ai/providers" -H 'Content-Type: application/json' \
  -d '{"action":"select","provider":"anthropic","settings":{"model":"claude-opus-4-8"}}'

# 4. Validate with a live probe
curl -s -X POST "$BASE/ai/providers" -H 'Content-Type: application/json' \
  -d '{"action":"validate","provider":"anthropic"}'
# -> {"ok": true, "detail": "anthropic responded"}
```

Anthropic can also authenticate via an `ant auth login` profile instead of a
raw key — if a profile is active on the host, the SDK resolves it and you can
skip step 2.

### B) OpenAI

```bash
python3 -m pip install --user openai
curl -s -X POST "$BASE/ai/providers" -H 'Content-Type: application/json' \
  -d '{"action":"set_auth","provider":"openai","secret":"sk-..."}'
curl -s -X POST "$BASE/ai/providers" -H 'Content-Type: application/json' \
  -d '{"action":"select","provider":"openai","settings":{"model":"gpt-4o"}}'
curl -s -X POST "$BASE/ai/providers" -H 'Content-Type: application/json' \
  -d '{"action":"validate","provider":"openai"}'
```

### C) A local or hosted OpenAI-compatible endpoint

Covers a local **vLLM** or **Ollama** server, **OpenRouter**, a **LiteLLM**
proxy, or a future local **open-weight** model — anything that speaks the OpenAI
chat API. Set a `base_url`; a key is optional for local servers.

```bash
python3 -m pip install --user openai
# e.g. a local vLLM/Ollama server
curl -s -X POST "$BASE/ai/providers" -H 'Content-Type: application/json' \
  -d '{"action":"select","provider":"openai_compatible",
       "settings":{"base_url":"http://localhost:11434/v1","model":"llama3.1"}}'
# (if the endpoint needs a key, set_auth for provider "openai_compatible" first)
curl -s -X POST "$BASE/ai/providers" -H 'Content-Type: application/json' \
  -d '{"action":"validate","provider":"openai_compatible"}'
```

### D) Back to no-LLM (default)

```bash
curl -s -X POST "$BASE/ai/providers" -H 'Content-Type: application/json' \
  -d '{"action":"select","provider":"null"}'
```

---

## 3. Confirm it's live

```bash
curl -s -X POST "$BASE/ai/chat" -H 'Content-Type: application/json' \
  -d '{"message":"what can you help me with?"}' | python3 -m json.tool
```

The response's `provider` and `mode` fields show which provider answered
(`"mode":"model"` once a real provider is active; `"mode":"deterministic"` on
null).

---

## 4. Environment-variable alternative (no API calls)

For a headless or scripted deploy, you can configure entirely via env vars the
node inherits — no `POST` calls needed:

| Variable | Effect |
|---|---|
| `POLARI_REASONING_PROVIDER` | Active provider (`anthropic`/`openai`/…). Overrides the stored selection. |
| `POLARI_REASONING_MODEL` | Default model for the active provider. |
| `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` | The provider's credential (read if no stored secret). |

`POLARI_AUTO_MAX_LEVEL` / `POLARI_ALLOW_HIGH_AUTHORITY` on the **MCP server** side
govern how much the AI may do unattended — separate from provider setup; see the
MCP `README.md`.

---

## 5. Security notes

- **Never hand a secret to the AI.** There is intentionally no MCP tool that sets
  a credential. The AI can read status, propose a selection, and validate; you
  enter the key via `set_auth` (or an env var). Anything the AI does is written to
  the provenance log — keep secrets out of that path.
- Stored secrets live in `data/reasoning_secrets.json` (`chmod 600`, git-ignored);
  the active selection in `data/reasoning_config.json` (git-ignored). Rotate a key
  by re-running `set_auth`; remove a provider's key by deleting its entry.
- No response ever returns a secret value — only `has_credential: true|false`.

---

## 6. Troubleshooting

| Symptom | Fix |
|---|---|
| `needs: ["pip install X"]` | Install the SDK into the **same** Python env the node runs in (`--user` if bare-metal). |
| `validate` → `not ready: …` | Work the `needs` list; re-check `GET /ai/providers`. |
| `validate` → a connection error | SDK + selection are fine; the endpoint/key is wrong (esp. a local `base_url`). |
| `/ai/chat` still says `mode: deterministic` after selecting a real provider | The provider isn't `ready` (missing SDK or key) so it fell back to null — check status. |
| Changed a provider file but nothing changed | Provider **code** changes need a node restart; **selection/secret** changes take effect on the next request (no restart). |

---

## Where this plugs in

Once a provider is active, the whole stack uses it: the in-app assistant panel
(text / voice / VR), the `/ai/chat` endpoint, and any MCP-driven reasoning — all
through the same gated capability and provenance log. Switching providers later
is a single `select` call; nothing else changes.
