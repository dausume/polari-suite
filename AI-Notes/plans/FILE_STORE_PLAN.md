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
- The filer UI on :9001 has no login (MinIO's console had one): behind the proxy's `files.` host as before; a posture
  decision for prod (drop the `files.` host, or front it with the proxy's auth).
- The `MINIO_*` names stay as the compatibility contract; a rename to `FILE_STORE_*` across setup scripts, compose
  files, the backend and PSC is a separate, mechanical arc if wanted.
- Frontend use of the STS door (a browser exchanging the user's token for temporary keys) is not built — today the
  backend presigns; the door exists for when a client needs direct S3.
