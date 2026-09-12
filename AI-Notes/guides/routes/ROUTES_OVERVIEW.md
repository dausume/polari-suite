# Deployment routes: one Polari, four ways to get it

Polari has to work for two very different people at once. One is sitting at a desktop and wants to follow directions, step by step, with nothing to remember. The other is a script, a swarm, or an AI session working over ssh that wants to do the same thing in one command with no questions. And both have to work whether the machine is on the internet or not.

So every route ends at the same place, a Polari instance with modules and apps, but starts differently. Pick the row that describes you.

| Route | Who it is for | How it starts | Online | Offline |
|---|---|---|---|---|
| Desktop | a person at a computer, following directions | the installer (a deb), then the App Store | yes | yes, with the offline installer |
| Server | a person setting up a public site | one line pasted into the server's console, then the guided screens | yes | no, a server needs the internet |
| Automated | scripts, swarm, ssh, CI | `pol prod apply --yes` with answers as environment variables, `pol deploy` to remote nodes | yes | yes, from a release pool |
| AI-driven | an assistant working through `pol` and the API | the same commands, plus `pol prod facts` for machine-readable state and the API for every action | yes | yes |

Whatever the route, modules and apps can then be set up by any of four means, and the same command proves all four: the console, the apps, the interfaces, and the topology. That is the subject of [Modules and apps by every route](modules-by-every-route.html).

The pages in this section describe each route as it exists today, with the commands that are real. Where something is still yours to do, the page says so.
