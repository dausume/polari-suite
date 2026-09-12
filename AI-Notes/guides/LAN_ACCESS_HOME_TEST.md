# Reaching Polari on your home network

This page is about one thing: a Polari instance running on a computer in your house, reached from the other devices in the house, phones and laptops on the same wifi. Nothing here is published to the internet. Making an instance public is a different job, done by the server route, and this page deliberately stops short of it.

## 1. Private addresses: what they are and why they are safe to write down

Every device on a home network has a private address. Three ranges are reserved for exactly this, and routers on the internet refuse to carry them, so a private address only means something inside the network it belongs to:

| range | typical use | example addresses |
|---|---|---|
| 192.168.0.0 to 192.168.255.255 | most home routers | 192.168.1.1 (the router), 192.168.1.50 (a computer) |
| 10.0.0.0 to 10.255.255.255 | larger networks, VPNs, isles | 10.0.0.1 (the router), 10.0.0.42 (a computer) |
| 172.16.0.0 to 172.31.255.255 | some routers, docker's own networks | 172.16.0.1, 172.17.0.2 |

Two houses can both have a computer at 192.168.1.50 and nothing conflicts, because those addresses never leave either house. That is also why a private address on its own gives nobody a way in: from the internet it points nowhere.

Your computer's own private address is shown by the router's device list, by `pol prod addresses`, or by `hostname -I`. In the examples below it is 192.168.1.50; put yours in its place.

## 2. Two scopes, kept apart

| | on the home network (this page) | on the internet (the server route) |
|---|---|---|
| who can reach it | any device on the home wifi | anyone |
| DNS | a name that resolves to the private address, no registrar involved | a real domain with records at a DNS host |
| the address | a private address, useless from outside | a public address the whole internet can route to |
| certificate | signed by Polari's own authority, imported once on each device | publicly trusted, from Let's Encrypt |
| exposure | none, the router forwards nothing in | ports 80 and 443 open to the world |

## 3. A name for a private address

Browsers and Polari's own frontends want a name, not a number, and the name has to end in a real-looking domain for cookies and certificates to behave. Two ways, both free:

- **nip.io.** A public DNS service that turns an address written into a name back into that address: `192-168-1-50.nip.io` resolves to 192.168.1.50 for anyone who asks, but only devices on your network can actually reach it. Polari's staging and the local-instance profile use this. It needs the internet for the lookup, nothing more.
- **Your own hosts entries, offline.** Add a line to each device's hosts file, or to the router's DNS, mapping a name of your choosing to the private address. This works with no internet at all, which is what an isle does for its members automatically.

## 4. Running it

The local-instance profile does all of this on the computer it runs on:

```
pol prod profile use local-instance
pol prod apply
```

It answers for the computer's private address under a nip.io name, generates a certificate from Polari's own authority, and starts the instance with user logins. Devices on the wifi open `https://prf.192-168-1-50.nip.io`, import the authority's certificate once, and are in. `pol prod status` shows the names and addresses in use.

## 5. What this does not do

It does not open your router. Nobody outside the house can reach the instance, and no record of it exists anywhere public. When you want that, the server route, a real domain and a publicly trusted certificate are the next page, and the address involved is then a public one that belongs to the server, never the one in your house.
