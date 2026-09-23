#!/usr/bin/env python3
"""polari-jenkins/next-slot.py — WHEN a change to main may RUN (rule 5, his ruling 2026-09-22).

    next-slot.py <CI_MAIN_RELEASE_AT> <since-epoch>   → the epoch of the FIRST slot after `since`
                                                        '' = now (no schedule) · 'BAD <why>' = a bad spec
Grammar:  now · midnight (= 00:00 daily) · HH:MM (daily) · <weekday> HH:MM (weekly, e.g. "sun 02:00").
The clock is the process's TZ (the controller carries the device's).
"""
import sys, datetime, re

spec, since = sys.argv[1].strip().lower(), int(sys.argv[2])
if spec == 'now':
    sys.exit(0)
if spec == 'midnight':
    spec = '00:00'
days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
m = re.match(r'^(?:([a-z]{3})[a-z]*\s+)?(\d{1,2}):(\d{2})$', spec)
if not m or int(m.group(2)) > 23 or int(m.group(3)) > 59 or (m.group(1) and m.group(1) not in days):
    print('BAD not now|midnight|HH:MM|<weekday> HH:MM')
    sys.exit(0)
t = datetime.datetime.fromtimestamp(since).astimezone()
slot = t.replace(hour=int(m.group(2)), minute=int(m.group(3)), second=0, microsecond=0)
if m.group(1):
    slot += datetime.timedelta(days=(days.index(m.group(1)) - slot.weekday()) % 7)
if slot <= t:
    slot += datetime.timedelta(days=7 if m.group(1) else 1)
print(int(slot.timestamp()))
