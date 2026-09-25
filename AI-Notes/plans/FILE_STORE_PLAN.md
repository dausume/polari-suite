# File store — MinIO → SeaweedFS (fs-1)

## Why (2026-09-25)
Bringing the node stack up for the tensor arc's browser pass, `prf-file-store` failed to build: **`minio/minio` no
longer exists on Docker Hub** (the repository, not a tag; quay.io too; the GitHub repo is archived since 2026-04). The
same class of upstream death as bitnami/redis (memory). Three candidates were checked against the live repos:

| | licence | maintenance (2026-09-25) | Keycloak / OIDC |
|---|---|---|---|
| SeaweedFS | Apache-2.0 | 35k★, ~weekly releases (4.47 on 09-14), 12 years, one lead maintainer | native STS AssumeRoleWithWebIdentity + an OIDC guide |
| RustFS | Apache-2.0 | 34k★ in a year, `1.0.1-preview.N` daily — pre-1.0; a MinIO re-implementation (lineage worth the licence gate's look) | claims OIDC/SSO |
| Garage | AGPL-3.0 | 4.6k★, small non-profit, steady v2.4 | none (keys only) |

**D-fs-1 — RATIFIED 2026-09-25 (his: "SeaweedFS").**

## What was built (branch `dev-fs-1` in the suite, polari-rf-node, political-scorecard-backend)
- **`polari-rf-node/prf-file-store/`** — the ONE definition: `Dockerfile` (`FROM chrislusf/seaweedfs:4.47`, pinned),
  `entrypoint.sh` (renders `s3.json` from `MINIO_ROOT_USER/PASSWORD` — refuses to start without them — and, when the realm
  issuer is in the env, `iam.json`; then `weed server -dir=/data -s3 -s3.port=9000 -filer -filer.port=9001 …` through the
  image's own entrypoint), `README.md`. The contract every consumer had is kept: S3 :9000, UI :9001, MINIO_* knobs,
  buckets by the applications. Proven with the backend's own client (`minio-py` 7.2.15): make/list/put/get/presign/delete.
- **The Keycloak door — STS in CLAIM mode only.** Policies named after the realm roles (`polari-admin` s3:*,
  `polari-developer` write + buckets, `polari-user` write, `polari-viewer`/`default-roles-polari` read); the token's
  top-level `roles` claim is the `policyClaim`; RoleArn omitted / the sentinel. **No concrete roles, no Bearer-on-S3**:
  trust policies see only `oidc:iss/sub/aud`, so with roles defined any realm token could AssumeRole PolariAdmin
  (observed), and locking the roles broke Bearer, which goes through the same gate. Proven live against the running
  realm with the backend service account's token (role `polari-developer`): claim-mode temp keys → create bucket, put,
  list, delete OK; concrete `RoleArn` → refused; Bearer → 403.
- **Realm** (both imports): mappers on `polari-frontend` / `polari-shell` / `polari-backend` — realm roles as a
  top-level `roles` claim, audience `polari-file-store`; a bearer-only client `polari-file-store` documents the audience.
- **Wiring**: `docker-compose.staging-nip.yml` (build `./prf-file-store`, the CA mounted, a real healthcheck), suite
  `docker-compose.yml` + `docker-compose.prod.yml` (context `./polari-rf-node/prf-file-store`), `pol-file-store/`
  (the PoC compose now builds from there; its Dockerfile is gone), PSC `docker-compose-test.yml` (`psc-minio-test`
  builds the same image — its MinIO image was dead too), `pol shell publish` uploads through the filer
  (`POST :9001/buckets/<bucket>/<key>`; no `mc`), `pol config` wording.
- Licence gate: `AI-Notes/evaluations/FILE_STORE_LICENSE_GATE.md`.

## Not done / his
- ~~The filer UI on :9001 has no login~~ CLOSED 2026-09-25 (his question "so it cannot connect to keycloak and is not
  secure?"): the filer's browser page has no login of its own and cannot be put behind Keycloak, so it is NOT
  published any more — the `files.` host is gone from every proxy template (and the SANs), :9001 is not mapped to the
  LAN (the PoC binds it to loopback), and the store is reached ONLY through the S3 API (:9000 — root keys, or temporary
  keys minted from a Keycloak token). Inside the docker network the filer stays reachable for the suite's own tooling
  (`pol shell publish`), the same trust the other service-to-service ports have. Verified live: `files.` host → 503
  (no such vhost), `s3.` → 403 without keys, :9001 from the LAN → refused.
- The `MINIO_*` names stay as the compatibility contract; a rename to `FILE_STORE_*` across setup scripts, compose
  files, the backend and PSC is a separate, mechanical arc if wanted.
- ~~Frontend use of the STS door is not built~~ → **fs-2 BUILT 2026-09-25 (his condition for closing the UI: "so long as
  we can make a way to access it through polari which should be able to be secured")** — see §5.
- A browser exchanging the user's token for temporary keys ITSELF (direct S3 from Angular, uploads without the
  backend) is still not built; fs-2 does the exchange in the backend, per request, as the caller.

## §5 fs-2 — browsing the store THROUGH Polari, as the signed-in person (built 2026-09-25, `dev-fs-1`)

The Polari door that replaces the closed filer UI. Nothing here lends the backend's root keys to a browser:

- `accessControl/store_identity.py` — `caller_store_client(manager, request, verb)`: the caller's Bearer (the
  realm access token the frontend already sends) is exchanged with the store (`AssumeRoleWithWebIdentity`, claim
  mode) for temporary S3 keys, cached per token until they expire; the routes act with THOSE keys, so the STORE
  applies the caller's realm roles (`who.enforced_by: store`). Anonymous → 401 (a different answer from 403, per
  the auth middleware's contract); an expired session → 401 `session invalid or expired`. When the store has no
  OIDC door (dev without an issuer, a bare `weed`) the exchange fails and the backend applies the SAME role table
  (`ROLE_ALLOWS`, mirrored from `prf-file-store/entrypoint.sh`) with its own connection — the answer says so
  (`who.enforced_by: backend`); `FILE_STORE_BACKEND_GATE=no` turns that fallback into a 503.
- Routes on the existing `ObjectStorageAPI` (`/object-storage`, the class that already owned status/buckets):
  - `GET /object-storage/browse` — the caller's buckets; `?objects=1&limit=&prefix=&expires=` adds every object
    across them (flat rows, capped per bucket and SAID: `truncated_buckets`, `denied_buckets`), each with a
    time-limited download link signed with the CALLER's keys against `MINIO_PUBLIC_URL` (the browser-reachable
    `https://s3.prf.<ip>.nip.io` — now set for the node stack's backend; it was missing, so links would have named
    the docker-internal host).
  - `GET /object-storage/browse/{bucket}?prefix=&limit=&expires=` — one bucket's objects.
  - `GET /object-storage/browse/{bucket}/link?key=&expires=[&go=1]` — one link (or a 302 to it).
- The page: `/display/file-store` (seeded with the module pages, `module_pages_seed.py`): three configured
  `api-structured-panel`s — who you are to the store (sub, roles, which side enforces), buckets, objects with
  their links. No new component: `structured-payload-panel` now renders a URL-valued cell as a link (`open ↗`)
  instead of a wall of signed-query text — the one generalization, alongside the `latex` column format of pf-3.
- **Verified live 2026-09-25 (node stack on the swarm, backend + frontend images rebuilt and rolled):** anonymous →
  401 `sign in to browse the file store`; a garbage Bearer → 401 `session invalid or expired`; the backend's own
  service-account token (roles polari-developer) → 200, `who.enforced_by: store`, the bucket `polari-docs` and its
  one object with a link signed against `s3.prf.<ip>.nip.io`; that link fetched from the host with NO Authorization
  → 200 and the object's bytes; the same link with one character changed → 403; an unknown bucket → 404 with the
  store's own `NoSuchBucket`; `/display/file-store` renders the three panels, and signed-out shows the 401 wording
  in each (the signed-in view is his to look at — I never enter credentials). Gotcha met on the way: a token minted
  through the docker-internal Keycloak host carries `iss …:8080` and the backend's validator refuses it; mint through
  the public realm URL. The proof object `polari-docs/notes/fs2-proof.txt` was left in the store.
