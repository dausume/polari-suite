#!/usr/bin/env python3
"""polari-jenkins/setup/protocol.py — THE EMITTER of `polari-pipeline-setup/1`.

ci-11a. `setup.sh --json` walks the SAME step functions the interactive
walkthrough walks; every `check`, `explain`, `question`, `action` and `where`
it produces is appended to a record file by `setup/json.sh`, and this file
turns that record file into the one JSON document on stdout.

LAYER BOUNDARY (his rule 2026-09-19, "keep different pieces logically
separate, like CLI vs JavaFX"): nothing in this file — or anywhere under
polari-jenkins/ — knows that a desktop shell exists. It emits a protocol.
Which of those actions a shell may run, and how, is the SEPARATE allowlist
`polari-jenkins/shell-verbs.json`; how a page renders them is the SEPARATE
`cicd` module. There is no "if the shell is calling" branch anywhere.

The record file is US (\\x1f) separated fields, RS (\\x1e) separated records:

    meta      <key> <value>
    step      <name> <index> <total> <title>
    explain   <text>
    check     <OK|WARN|FAIL> <name> <value> <fix>
    question  <key> <label> <kind> <default> <answered> <options>
    action    <id> <label> <0|1 privileged> <verb> <0|1 done> <why> <params>
    where     <what> <url> <scopes>
    todo      <step> <text> <command>
    stepstate <done|todo> <note>

`options` is `value=label|value=label`; `params` is `key=value|key=value`.

THE STATE RULE, in one place so the page and the shell never disagree:
  done     every check is OK and every question is answered
  blocked  a check FAILed and the step carries a privileged action
  todo     anything else
  skipped  the step does not apply to this device's mode
"""
import json
import os
import re
import sys

US = '\x1f'
RS = '\x1e'

PROTOCOL = 'polari-pipeline-setup/1'
VERDICTS = ('OK', 'WARN', 'FAIL')
KINDS = ('choice', 'text', 'secret', 'confirm', 'checklist')
STATES = ('done', 'todo', 'blocked', 'skipped')


#: the allowlist, beside this file. Loaded so an action is validated BEFORE it
#: is ever offered — "on BOTH sides" means here as well as in whoever executes it.
VERBS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'shell-verbs.json')


def load_verbs(path=VERBS_FILE):
    try:
        with open(path, 'r', encoding='utf-8') as fh:
            return (json.load(fh) or {}).get('verbs') or {}
    except (OSError, ValueError):
        return {}


#: a parameter value the EXECUTOR fills in — `{answer}` is what the person typed or chose. It is
#: checked against the verb's regex where it is substituted, not here, because here there is nothing
#: to check yet. Only this exact shape is tolerated: anything else must be a real, validated value.
PLACEHOLDER = re.compile(r'^\{[a-z]+\}$')


def action_refusal(action, verbs):
    """Why this action may NOT be offered, or None. The page never sees a refused action."""
    verb = action.get('verb') or ''
    spec = verbs.get(verb)
    if spec is None:
        return 'names no verb in shell-verbs.json (%s)' % (', '.join(sorted(verbs)) or 'the file is unreadable')
    declared = spec.get('params') or {}
    given = action.get('params') or {}
    for key in given:
        if key not in declared:
            return 'passes %r, which the verb %r does not declare' % (key, verb)
    for key, pattern in declared.items():
        if key not in given:
            return 'omits the required parameter %r of the verb %r' % (key, verb)
        if not pattern.startswith('^') or not pattern.endswith('$'):
            return 'the verb %r declares an unanchored regex for %r' % (verb, key)
        if PLACEHOLDER.match(given[key]):
            continue
        try:
            if not re.match(pattern + r'\Z', given[key]):
                return 'the value of %r does not match the verb %r\'s regex %s' % (key, verb, pattern)
        except re.error:
            return 'the verb %r declares an unusable regex for %r' % (verb, key)
    return None


#: the verb a non-secret question is written through
ANSWER_VERB = 'setup-answer'


def bind_question(step_name, question, verbs):
    """The action binding a question carries, or None.

    A `choice`, `text`, `confirm` or `checklist` question is one device.env knob, so it binds to
    `setup-answer` with the value left as the placeholder `{answer}`: the executor substitutes what the
    person typed or chose and validates it against the verb's own regex.

    A `secret` question binds to NOTHING. Its value goes to `secrets-put` on standard input, collected by
    the executor's own prompt — a secret in a parameter is a secret in the process list, and a secret in a
    page is a secret in the page. The step's `actions` carry that verb; the question carries only whether
    the device already has one.
    """
    if question.get('kind') == 'secret':
        return None
    key = str(question.get('key') or '')
    if not key or '/' in key:
        return None
    binding = {'verb': ANSWER_VERB,
               'params': {'step': step_name, 'key': key, 'value': '{answer}'}}
    return None if action_refusal(binding, verbs) else binding


def _pairs(blob, sep='|'):
    out = []
    for part in blob.split(sep):
        if not part:
            continue
        k, _, v = part.partition('=')
        out.append((k, v))
    return out


def read_records(path):
    with open(path, 'r', encoding='utf-8') as fh:
        raw = fh.read()
    recs = []
    for chunk in raw.split(RS):
        if not chunk:
            continue
        fields = chunk.split(US)
        if fields and fields[-1] == '':
            fields.pop()
        if fields:
            recs.append(fields)
    return recs


def _f(fields, i, default=''):
    return fields[i] if len(fields) > i else default


def build(recs):
    meta = {}
    steps = []
    todo = []
    cur = None
    for r in recs:
        kind = r[0]
        if kind == 'meta':
            meta[_f(r, 1)] = _f(r, 2)
        elif kind == 'step':
            cur = {
                'name': _f(r, 1),
                'index': int(_f(r, 2, '0') or 0),
                'total': int(_f(r, 3, '0') or 0),
                'title': _f(r, 4),
                'state': 'todo',
                'explain': '',
                'checks': [],
                'questions': [],
                'actions': [],
                'where': [],
            }
            cur['_own'] = 'todo'
            cur['_note'] = ''
            cur['_skip'] = ''
            steps.append(cur)
        elif kind == 'todo':
            # a to-do may be emitted before any step (a refused answer, say), so it
            # is handled ahead of the "inside a step" guard
            todo.append({'step': _f(r, 1), 'text': _f(r, 2), 'command': _f(r, 3)})
        elif cur is None:
            continue
        elif kind == 'explain':
            text = _f(r, 1)
            cur['explain'] = (cur['explain'] + '\n\n' + text).strip() if cur['explain'] else text
        elif kind == 'check':
            verdict = _f(r, 1, 'WARN')
            cur['checks'].append({
                'name': _f(r, 2),
                'value': _f(r, 3),
                'verdict': verdict if verdict in VERDICTS else 'WARN',
                'fix': _f(r, 4),
            })
        elif kind == 'question':
            q = {
                'key': _f(r, 1),
                'label': _f(r, 2),
                'kind': _f(r, 3, 'text') if _f(r, 3, 'text') in KINDS else 'text',
                'default': _f(r, 4),
                'answered': _f(r, 5),
            }
            opts = [{'value': v, 'label': l} for v, l in _pairs(_f(r, 6))]
            if opts:
                q['options'] = opts
            cur['questions'].append(q)
        elif kind == 'action':
            a = {
                'id': _f(r, 1),
                'label': _f(r, 2),
                'privileged': _f(r, 3) == '1',
                'verb': _f(r, 4),
                'done': _f(r, 5) == '1',
                'why': _f(r, 6),
            }
            params = dict(_pairs(_f(r, 7)))
            if params:
                a['params'] = params
            cur['actions'].append(a)
        elif kind == 'where':
            cur['where'].append({'what': _f(r, 1), 'url': _f(r, 2), 'scopes': _f(r, 3)})
        elif kind == 'stepstate':
            cur['_own'] = _f(r, 1, 'todo')
            cur['_note'] = _f(r, 2)
        elif kind == 'skip':
            cur['_skip'] = _f(r, 1)
    return meta, steps, todo


def settle_state(step):
    """THE ONE state rule — the page and the shell both read this field, never re-derive it."""
    if step['_skip']:
        return 'skipped'
    failed = [c for c in step['checks'] if c['verdict'] == 'FAIL']
    privileged = [a for a in step['actions'] if a['privileged'] and not a['done']]
    if failed and privileged:
        return 'blocked'
    unanswered = [q for q in step['questions'] if not str(q.get('answered') or '')]
    if step['_own'] == 'done' and not unanswered and not failed:
        return 'done'
    return 'todo'


def main(argv):
    if len(argv) < 2:
        sys.stderr.write('protocol.py <record-file> [--action <id> --ok <0|1> --exit <n> --output <file>]\n')
        return 2
    recs = read_records(argv[1])
    meta, steps, todo = build(recs)

    action = ok = exit_code = out_file = None
    rest = argv[2:]
    while rest:
        flag, rest = rest[0], rest[1:]
        val, rest = (rest[0], rest[1:]) if rest else ('', [])
        if flag == '--action':
            action = val
        elif flag == '--ok':
            ok = val == '1'
        elif flag == '--exit':
            exit_code = int(val or 0)
        elif flag == '--output':
            out_file = val

    verbs = load_verbs()
    for s in steps:
        for q in s['questions']:
            binding = bind_question(s['name'], q, verbs)
            if binding:
                q['action'] = binding
        kept = []
        for a in s['actions']:
            why = action_refusal(a, verbs)
            if why is None:
                kept.append(a)
            else:
                todo.append({'step': s['name'],
                             'text': 'the action %r was NOT offered: it %s' % (a['id'], why),
                             'command': 'pol jenkins verbs'})
        s['actions'] = kept
    for s in steps:
        s['state'] = settle_state(s)
        note = s.pop('_note', '')
        s.pop('_own', None)
        s.pop('_skip', None)
        if note:
            s['note'] = note

    complete = sum(1 for s in steps if s['state'] in ('done', 'skipped'))
    ready = meta.get('ready') == 'true'
    doc = {
        'protocol': PROTOCOL,
        'device': {
            'mode': meta.get('mode', 'suite'),
            'ready': ready,
            'name': meta.get('device_name', ''),
            'target': meta.get('target', ''),
            'secrets_posture': meta.get('secrets_posture', ''),
            'at': meta.get('at', ''),
        },
        'steps': steps,
        'todo': todo,
    }
    if action is not None:
        output = ''
        if out_file:
            try:
                with open(out_file, 'r', encoding='utf-8', errors='replace') as fh:
                    output = fh.read()[-4000:]
            except OSError:
                output = ''
        doc['action'] = action
        doc['ok'] = bool(ok)
        doc['exitCode'] = int(exit_code or 0)
        doc['output'] = output
        if len(steps) == 1:
            doc['step'] = steps.pop(0)
            doc.pop('steps', None)
    else:
        doc['summary'] = {
            'complete': complete,
            'total': int(meta.get('total') or len(steps)),
            'ready': ready,
            'blocking': meta.get('blocking', ''),
        }
    if meta.get('partial') == '1':
        # one step was asked for: the summary would be a lie about the other seven
        doc.pop('summary', None)
    json.dump(doc, sys.stdout, indent=1)
    sys.stdout.write('\n')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
