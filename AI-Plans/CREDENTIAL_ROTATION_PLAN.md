# Rotating the credentials exposed in the router image — TABLED

**Date:** 2026-08-10 · **Status: NOT EXECUTED. Do not run any of this
without Dustin present.** Written because the exposure is real
(`ARTIFACT_HYGIENE_PLAN.md` §0a) but rotation is the most dangerous
thing in the whole arc: these are the credentials the isle uses to
reach its own router. Get the order wrong and you lock yourself out of
the device that carries the network.

## 1. What is exposed, and what each rotation actually risks

| material | where | if rotation goes wrong |
|---|---|---|
| dropbear host keys (ed25519, rsa) | `/etc/dropbear/` | **low** — clients see a host-key-changed warning; the isle scripts already use `StrictHostKeyChecking=no` |
| root password hash (MD5-crypt) | `/etc/shadow` | **medium** — the provisioning bootstrap tries `ROUTER_DEFAULT_PASSWORD`, `root`, then empty; change it without updating that and a rebuild cannot bootstrap |
| `isle-router-key` keypair | `/etc/isle-mesh/router/ssh/` + router `authorized_keys` | **HIGH — this is the lockout risk.** Replace `authorized_keys` before the new private key is in place and every isle script loses access to the router |
| uhttpd TLS keypair | `/etc/uhttpd.{crt,key}` | **low** — LuCI web UI only; nothing in the isle depends on it |

**The one that matters is the SSH key.** Everything else is
inconvenience.

## 2. Why "just rotate it" is wrong

Three traps, in the order they will bite:

1. **Append before you remove.** `authorized_keys` must hold BOTH keys
   until the new one is proven. The obvious `echo new > authorized_keys`
   is the lockout.
2. **A live router is not a rebuilt router.** The running router was
   provisioned months ago; a fresh one gets keys from `router-init`.
   Rotating the live device and rotating the build path are two
   different jobs and only the first is urgent.
3. **Rotation does not un-publish anything.** Every clone of the public
   repo still has the old keys. Rotation makes them *useless*; it does
   not make them *secret*. So there is no race — no reason to rush this
   and every reason to do it carefully.

## 3. The cautious sequence (SSH key — the risky one)

Preconditions: physical or console access to the router VM
(`virsh console openwrt-isle-router`), so a lockout is recoverable.
**Do not start without that.** Also: this is on isle-core, whose Claude
owns the repo — leave it a NOTES entry.

1. **Prove console recovery FIRST**, before touching anything. Open
   `virsh console`, log in, exit. If that does not work, stop here —
   without it, step 5 has no undo.
2. Back up `/etc/dropbear/authorized_keys` on the router and the whole
   `/etc/isle-mesh/router/ssh/` directory on the host.
3. Generate the NEW keypair alongside the old one (do not overwrite
   `isle_router_key`; write `isle_router_key.new`).
4. **APPEND** the new public key to the router's `authorized_keys`.
   Both keys now work.
5. Verify the new key alone works, non-interactively, from a fresh
   connection: `ssh -o BatchMode=yes -i isle_router_key.new root@<ip>`.
   **If this fails, stop — you are still on the old key, nothing is
   broken.**
6. Only now swap the host-side key into place (`isle_router_key.new` →
   `isle_router_key`, old one kept as `.old`).
7. Run something real end to end — `isle status`, a DNS operation, a
   `router.sh` verb — confirming the isle itself still drives the router.
8. **Only after that**, remove the old public key from
   `authorized_keys`. This is the irreversible step and it goes last.
9. Keep the `.old` key for a few days. Delete it once nothing has
   complained.

## 4. The other three (do after, independently)

- **Root password:** set a new one, then update
  `ROUTER_DEFAULT_PASSWORD` / the cached password file
  (`/etc/isle-mesh/router/ssh/.cached_password`) in the same change.
  A rebuilt router uses the pristine image's blank password, which
  accepts anything — so the build path is unaffected either way.
- **Dropbear host keys:** delete them and restart dropbear; it
  regenerates. Expect host-key warnings on first reconnect.
- **uhttpd keypair:** regenerate or simply delete — OpenWrt recreates it.

Each of these is independently revertible from the backups in step 2.

## 5. What makes this safe to postpone

- The images are already untracked, so the exposure is not growing.
- The router is reachable only from inside the isle; the exposed keys
  are not usable from the internet without first being on the mesh.
- A **fresh** router built by `build-router-image.sh` is pristine — it
  never carries these credentials, so anything built from here on is
  already clean.

The residual risk is someone who (a) has the public repo history and
(b) is already on the isle network. That is a real but narrow window,
and it is the reason to do this deliberately rather than never.

## 6. Decide before executing

- Do it on the live router, or rebuild the router from the pristine
  image and re-provision (cleaner, but a network outage — and the isle
  runs on it)?
- Same window as the history purge, or separate? (Separate is safer:
  two irreversible operations in one window means an ambiguous failure.)
- Who is at the console while it happens?
