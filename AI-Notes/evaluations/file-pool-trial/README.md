# The file store across machines: two trials by hand (2026-11-22)

What these are for: `AI-Notes/plans/STORAGE_ROLES_PLAN.md`, sections 9.11 (what was seen) and 9.12 (what follows).

Both scripts run the pinned file store program (SeaweedFS 4.47, see `../FILE_STORE_LICENSE_GATE.md`) as plain
processes of the normal user, on one machine, in a folder you name. No container, no root, nothing on the isle.
The program leaves socket files in `/tmp`; the scripts remove the ones they caused.

| File | What it tries |
|---|---|
| `pool-proof.py` | One pool: one index, three storage processes on three folders. Copies, labels, a partition going away, the read-only rule, the S3 door, and with `mount` the file space as an ordinary folder. |
| `link-proof.py` | Two separate stores. A folder of one is a link to a bucket of the other: fetch on read, take, work while the original is away, return, hold, drop. |
| `seen-pool.txt` | The output of `pool-proof.py <program> <folder> mount`. |
| `seen-link.txt` | The output of `link-proof.py <program> <folder> bridge allow`. |
| `seen-link-guard.txt` | The start of the output of `link-proof.py <program> <folder>`: with the guard on, a link to a loopback address lists the names and every read fails. |

To run one, the program has to be on the machine as a file. It was copied out of the image the Polari node already
uses; the scripts do not fetch anything.

```
python3 pool-proof.py <path of the weed program> <folder to work in> mount
```

```
python3 link-proof.py <path of the weed program> <folder to work in> bridge allow
```

`mount` needs FUSE for the normal user (`fusermount`). `bridge` needs Docker's own bridge interface to exist; it is
used only as a private address of this machine, no container is involved.
