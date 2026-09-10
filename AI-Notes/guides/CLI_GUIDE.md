# The Polari command line

Polari has two command-line tools, and most people never need either.

| Tool | Where it runs | What it drives |
|---|---|---|
| `pol` | A developer's machine, a server, a swarm manager | The suite: building, running, deploying, modules, certificates, production |
| `isle` | A device that is part of an isle | The isle itself: creating and joining, apps, exposure, hardware guests |

Everything the graphical doors do is also a command, so a developer or an AI assistant can do the same work from a terminal, over ssh, unattended.

## Two deployment routes

| Route | For | Entry point | The command behind it |
|---|---|---|---|
| **Home computer, an isle** | People. A private network on your own hardware; hardware apps (a printer, a radio) live here. | Install the `polari-complete` deb, open **Isle App Store**, choose **Create my own isle** | `sudo isle core-install` |
| **Server, a swarm** | Developers and AI-assisted deployments. A public site and distribution point, or a full stack with logins. No hardware setup. | `pol prod guide` | `pol prod apply --yes` with the answers as environment variables |

Both routes go into production and back out from a terminal. An isle opens one door at a time (`isle url expose`) and closes it (`isle url unexpose`); a swarm deploys a whole stack (`pol prod apply`) and removes it (`pol prod down`). Both can be driven from another machine with `pol deploy`.

## Who you are, and what you need

### An average user

You do not need the command line. Install the deb, open the Isle App Store, follow the doors. If you are ever asked to run something, it will be one line the store shows you, and this page tells you what it does:

```
sudo isle core-install        make this computer the core of your own isle
sudo isle onboard --host      join an isle and let this computer host apps
isle status                   is everything up
isle uninstall --everything   remove the isle from this computer
```

### A tester

You want to stand things up, check them, and tear them down, repeatedly, without remembering the details.

```
pol suite up --env staging     the combined stack on this machine
pol modules health             every module's state: online, degraded, failed, invalid
pol modules selftest <module>  one module's own checks, in its container
pol modules testplan           what a full run would cost on the standard computer
pol prod apply --yes           a production stack, unattended (answers from the environment)
pol prod status                the board: services, certificate, DNS, health
pol prod down                  remove it; the data volume stays
pol deploy status <node>       what runs on another machine, either route
```

### A developer

You work on one module or app as its own project, and you want the suite only when you need it.

```
pol project init <id>          this directory becomes a module project (VS Code files, git)
pol project lint | test        conformance and the module's selftests
pol project up | deploy        a local lean Polari with the module mounted, then admitted
pol project build              the module's deb
pol modules health <module>    what the registrar confirmed for it
pol modules conform            every module against the standard
pol node up --env dev          the framework alone, dev tier
pol build render | parity      the compose bundles from their annotated sources
pol proxy template <env>       the proxy config, one template for compose and swarm
```

### A researcher

You use Polari for the work itself: a science module, a simulation, a dataset, an app built from them. Most of that is the web interface; the command line is for getting the right modules onto an instance and taking your work with you.

```
pol modules list                     every module package (which have selftests)
pol apps list                        the apps this instance knows (use-case module sets)
pol apps plan <app>                  which modules an app needs and where they stand
pol apps deploy <app> --plan         what enabling it would do, touching nothing
pol apps deploy <app>                enable it: the modules are admitted, the pages appear
pol apps export <app> [file]         a portable package of the app to carry to another instance
pol modules get <module>             fetch a split-out module's code onto this instance
pol modules health <module>          is it fully online (classes, routes, seeds, pages)
pol hwmap scan | push                what this device can hand to a lab instrument guest
pol node up --env dev                a local instance of your own, for trying a module set
```

Data leaves the way it came in: a module's non-regenerable data is its `initialData`, served by the instance and pulled by another (`GET /modules/<m>/initial-data`), and an app's package is plain JSON. If you write a module, the developer path below is yours too; the standard format keeps it installable by anyone.

### An operator

You run an isle or a server for other people.

```
pol prod guide                 the production walkthrough (domain, certificate, logins, modules, installers)
pol prod cert                  a provider-issued, auto-approved certificate; renews itself
pol prod debs build            the installers the site hands out
pol security rotate prod       new credentials for the full profile
pol cert auto-renew status     is renewal installed
isle url entrypoint enable     this device may open doors to the outside
isle url expose <app>.isle --port <p> --user <who>
isle url exposures             what is open
pol deploy tier <node> hardware    label a machine for hardware apps (needs KVM + libvirt)
```

### An AI assistant

You cannot click. You can run every command above, read their output, and act on it. The conventions that make that safe:

- Every walkthrough has an unattended form. `pol prod apply --yes` takes its answers from `POL_PROD_*` variables; `pol deploy install <node> --route … --yes` runs the isle core install without its interactive walkthrough.
- `--dry-run` prints the exact commands without running them. Use it first.
- Irreversible steps refuse without an explicit flag: the isle wipe needs `--yes`, exposure needs a designated entrypoint, a certificate cannot be accepted for a text that is not the one served.
- State is readable as data: `pol modules health`, `pol prod status`, `pol deploy status`, `/api/modules/health`, `/api/terms/active`. Trust those over a command's return code.
- Remote work goes through `pol deploy` and the ssh aliases in the nodes manifest; nothing secret travels, the target generates its own credentials.
- The Polari instance itself is reachable to an assistant through its MCP surface, which proposes changes and never applies them without confirmation.

## Reading further

- `pol help` and `pol <module> help` are always current; the quick reference page lists every verb.
- `isle help` on any isle device.
- The pages under this section describe each tool's architecture and how to extend it.
