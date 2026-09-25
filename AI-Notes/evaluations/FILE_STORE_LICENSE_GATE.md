# Licence gate — the file store (fs-1, 2026-09-25)

Polari is GPLv3 ([[project-license-gplv3]]). The file store is a SEPARATE PROCESS the suite talks S3 to; nothing is
linked or vendored. Recorded anyway, per the gate.

| Component | Pin | Licence | Verified where | Verdict |
|---|---|---|---|---|
| SeaweedFS | `chrislusf/seaweedfs:4.47` (Docker Hub tag; GitHub release 4.47, 2026-09-14) | Apache-2.0 | github.com/seaweedfs/seaweedfs LICENSE (API: `license.spdx_id == Apache-2.0`) | tool — fine; one-way compatible into GPLv3; ships in debs/images without friction |
| the image's base + `weed` binary | inside the tag | Apache-2.0 (Go binary), Alpine base | image inspection | fine |
| MinIO (replaced) | — | AGPL-3.0, repo archived 2026-04, Docker Hub repository gone | github.com/minio/minio (`archived: true`) | RETIRED from the suite |
| RustFS (not adopted) | — | Apache-2.0, pre-1.0 previews | github.com/rustfs/rustfs | watch; a MinIO re-implementation — its lineage would need this gate's look before adoption |
| Garage (not adopted) | — | AGPL-3.0 | git.deuxfleurs.fr | compatible as a separate service, but no OIDC/STS |

Kept in mind: SeaweedFS has an "Enterprise Edition" (the binary prints a banner); the open release is what the suite
uses and needs — nothing in our configuration depends on enterprise features.
