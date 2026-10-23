# AGENTS.md — entry point for Codex (and any non-Claude agent) in the Polari suite

1. Read `CLAUDE.md` (the instance guide) and `README.md` (build/run/test). They bind you exactly as they bind Claude.
2. Read `AI-Notes/guides/CODEX_COLLABORATION_GUIDE.md` — who owns what, the mailbox channel, the git rules.
3. Your inbox is `AI-Notes/handoffs/codex/` (ledger in its README.md). Pull before reading:
   `git pull --ff-only && git submodule update --init --recursive`.
4. You push `codex/*` branches only — never `dev`, `main` or `test`. Commit innermost-first (submodule, then the pointer).
   Trailer: `Co-Authored-By: OpenAI Codex <noreply@openai.com>`.
5. Build and test through `pol` and the compose files, never hand-rolled docker/mvn/ng on the host (CLAUDE.md).
6. Nothing left running when you stop: twin sessions, hosted bridges, Blender/FreeCAD windows you opened.
