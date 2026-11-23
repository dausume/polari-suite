# Private and PII fields, kept apart from what is saved and pushed (`pii`)

Written 2026-11-23 on pol. State: NOT STARTED. The user put it after the engine work.

## The user's words (2026-11-23)

"For private values, they should not be in repos, only data saved to modules for later use explicitly should be used
that way. Maybe we should be defining some fields as being private or pii fields so they can be filtered out of what
gets saved and where, that way pii fields and tables can be kept seperate and have git rules to prevent them ever
being pushed up. But that is a later to do let's address the engine work first". Also: "this is not a public app
yet".

## What is known now

- 131 lines in 58 tracked files across six repos match the local privacy list (`.polari/privacy-denylist.txt`,
  gitignored). 110 of them are one private-network address. Some sit in seeded data files whose content may be tied
  to recorded hashes. Counts were taken on 2026-11-23; no values are written here.
- Today the guard is a person: every diff and commit message is scanned against the list before a push.

## The shape to work out later

1. A field-level mark on a row class (for example `private` / `pii`), read by the engine like its other field
   settings, so it is data and not code per class.
2. What the mark does: rows or fields so marked are saved apart (their own table or store). They are never written
   into seeds, module data files, exports or logs, and they are filtered from what is synced or published.
3. Git rules that refuse a commit or push carrying a marked value or a privacy-list hit (a hook in the forest's
   shared hooks path, plus a CI check), so the person stops being the only guard.
4. The existing hits: replace them at the tip, decide what happens to the seeded data files and their hashes, and
   decide whether the history matters while the repos are not public.

Nothing here is decided. It is to be planned with the user when the engine work allows.
