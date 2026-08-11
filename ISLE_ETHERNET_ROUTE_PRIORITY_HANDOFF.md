# Handoff — isle-mesh ethernet stole the default route from wifi

**Date:** 2026-08-11 · **Status: DIAGNOSIS + PROPOSED FIX, NOTHING
APPLIED.** ⛔ This is **isle-core's** territory (isle networking lives
on that box and its own Claude owns it). Written here only because
the symptom appeared on pol-core during a working session and would
otherwise be lost.

## 1. What happened (Dustin, 2026-08-11)

The wired connection "randomly took priority over the wifi." The
machine started trying to push ordinary wifi-destined traffic through
the **ethernet NIC dedicated to isle-mesh**, found nothing there, and
kept the ethernet as the higher-priority default anyway. **Result: the
session disconnected.**

Dustin's expectation, and why this reads as a bug: split DNS by the
agent should have been keeping those separate, and isle-mesh has
"taken over" that NIC — so the OS arguably should not have been
choosing it for general traffic at all.

## 2. The mechanism — why split DNS could not have prevented this

**Split DNS governs NAME RESOLUTION. It does not govern
DEFAULT-ROUTE SELECTION.** These are two independent layers:

| layer | decides | mechanism |
|---|---|---|
| split DNS | which resolver answers which domain | systemd-resolved / dnsmasq per-link domains |
| routing | which interface a packet leaves by | kernel route table, metrics |

Even a perfect split-DNS config cannot stop the kernel preferring a
route. Once a name resolves to an address, the **route** decides the
egress interface — and the isle-mesh NIC won that contest.

How it most likely won: NetworkManager auto-activated a profile on
the ethernet interface when it saw carrier, and that profile
installed a **default route with a lower (better) metric** than the
wifi's. NM's defaults favour wired over wireless precisely because
wired is normally the better link. Nothing about "isle-mesh owns this
NIC" is expressed to NM unless a profile says so — so from NM's point
of view it was just an ethernet link coming up.

The "could not find anything but kept priority" detail fits: a
default route's presence does not depend on reachability. Without
something actively withdrawing it, a dead default route stays
installed and keeps winning.

## 3. Proposed fix (NOT applied — needs isle-core + Dustin)

Make the isle-mesh NIC **structurally incapable** of becoming the
default route, rather than merely unlikely:

1. `ipv4.never-default yes` and `ipv6.never-default yes` on the
   isle-mesh connection profile — NM then accepts the link's config
   but **never installs a default route from it**. This is the
   load-bearing setting.
2. A deliberately high `ipv4.route-metric` (e.g. 3000) so that even
   if a default route appears by another path, wifi still wins.
3. `connection.autoconnect-priority` below the wifi profile's, and
   consider `connection.autoconnect no` if the isle stack brings the
   interface up itself.
4. If DHCP on that segment is what supplies the rogue default:
   `ipv4.ignore-auto-routes yes` (and `ipv4.ignore-auto-dns yes`,
   which also hardens the split-DNS intent).
5. Best: give the interface its **own NM profile bound to the MAC**,
   so these settings cannot be inherited by a generic "Wired
   connection 1" profile that NM auto-creates.

Verification, in this order:
- `nmcli -f NAME,DEVICE,TYPE,AUTOCONNECT,AUTOCONNECT-PRIORITY con show`
- `ip route show default` — expect exactly one default, via wifi.
- `nmcli device show <eth>` — confirm no `IP4.GATEWAY` in use.
- Unplug/replug the isle NIC and re-check `ip route show default`
  (the failure mode is carrier-triggered, so the test must include a
  carrier event).
- `resolvectl status` to confirm split DNS is still intact after.

## 4. Why this is worth fixing properly, not papering over

The failure is **silent and total**: no error, just everything
routed into a dead segment. It will recur on every carrier event
(reboot, cable touch, switch restart) until the profile forbids it.
And it is the kind of thing that will look like "the isle is down"
or "polari is unreachable" when the isle and polari are both fine —
a diagnostic trap worth removing.

## 5. Boundary

Do this on **isle-core**, with its Claude, which holds the isle
networking context. Nothing in this repo changes. If the isle agent
is the component that should own the NIC exclusively, the deeper fix
is for the agent to declare the interface unmanaged by NM
(`NM_CONTROLLED=no` / an `unmanaged-devices` rule) — that is an
isle-side design decision, not a polari one.
