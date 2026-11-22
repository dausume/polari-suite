#!/usr/bin/env python3
"""A by-hand look at two separate file stores on this machine (made-up machines A and B), where a folder of B is a
link to a bucket of A.  Plain processes of the pinned program, loopback only, a temporary folder.

usage: link-proof.py <weed program> <folder to work in> [help] [bridge] [allow]

  help     print the program's own help for the link commands and stop
  bridge   store A answers on the address of Docker's own bridge, a private address only this machine reaches
  allow    store B is started with its guard against private and loopback endpoints switched off
"""
import glob, json, os, re, signal, subprocess, sys, tempfile, time, urllib.error, urllib.request

W, BASE = sys.argv[1], sys.argv[2]
HELP = 'help' in sys.argv[3:]
ALLOW = 'allow' in sys.argv[3:]
T = tempfile.mkdtemp(dir=BASE, prefix='link-proof-')
H = '127.0.0.1'
# store A answers on a private address of this machine that only this machine and its containers reach (Docker's own bridge)
AH = subprocess.run(['ip', '-4', '-o', 'addr', 'show', 'docker0'], capture_output=True, text=True).stdout.split()[3].split('/')[0] if 'bridge' in sys.argv[3:] else H
HOST = {'A': AH, 'B': H}
STORES = {'A': dict(master=24333, volume=24080, filer=24888, s3=24334), 'B': dict(master=25333, volume=25080, filer=25888, s3=25334)}
procs, facts = {}, []
BEFORE = set(glob.glob('/tmp/seaweedfs-*'))      # the program puts its socket files there, whatever it is told


def say(what, value):
    facts.append((what, value)); print('%-70s %s' % (what, str(value).replace(AH, '<bridge address>') if AH != H else value), flush=True)


def start(name, *args, **kw):
    log = open('%s/%s.log' % (T, name), 'a')
    procs[name] = subprocess.Popen([W] + list(args), stdout=log, stderr=log, cwd=kw.get('cwd', T))


def stop(name):
    p = procs.pop(name, None)
    if p is None: return
    p.send_signal(signal.SIGTERM)
    try: p.wait(timeout=20)
    except subprocess.TimeoutExpired:
        p.kill(); p.wait()


def http(url, data=None, method=None, timeout=10, headers=None):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, data=data, method=method, headers=headers or {}), timeout=timeout) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except Exception as e:
        return None, str(e).encode()


def until(test, seconds=40, what=''):
    end = time.time() + seconds
    while time.time() < end:
        try:
            if test(): return True
        except Exception:
            pass
        time.sleep(0.4)
    say('TIMED OUT waiting for ' + what, ''); return False


def store(name):
    s = STORES[name]
    for sub in ('data', 'index'): os.makedirs('%s/%s/%s' % (T, name, sub), exist_ok=True)
    extra = ['-volume.allowUntrustedRemoteEndpoints', '-filer.allowUntrustedRemoteEndpoints', '-s3.allowUntrustedRemoteEndpoints'] if ALLOW and name == 'B' else []
    start('store-' + name, 'server', '-ip=' + HOST[name], '-dir=%s/%s/data' % (T, name), '-master.dir=%s/%s/index' % (T, name),
          '-master.port=%d' % s['master'], '-master.volumeSizeLimitMB=64', '-volume.port=%d' % s['volume'], '-volume.max=20',
          '-filer', '-filer.port=%d' % s['filer'], '-s3', '-s3.port=%d' % s['s3'], '-s3.port.iceberg=0', '-s3.port.lance=0', *extra, cwd='%s/%s' % (T, name))
    # the list of names is kept in the store's own folder (the program's default is the folder it was started in)


def shell(name, command, seconds=90):
    s = STORES[name]
    done = subprocess.run([W, 'shell', '-master=%s:%d' % (HOST[name], s['master']), '-filer=%s:%d' % (HOST[name], s['filer'])], input=command + '\nexit\n',
                          capture_output=True, text=True, timeout=seconds, cwd=T)
    lines = [l for l in (done.stdout + done.stderr).splitlines() if not re.match(r'[IWEF]\d{4} ', l) and l.strip() not in ('', '>')]
    return done.returncode, '\n'.join(lines).replace(AH, '<bridge address>') if AH != H else '\n'.join(lines)


def f(name, path): return 'http://%s:%d%s' % (HOST[name], STORES[name]['filer'], path)
def d(name, path): return 'http://%s:%d%s' % (HOST[name], STORES[name]['s3'], path)


def data_bytes(name):
    return sum(os.path.getsize(os.path.join(a, x)) for a, _, xs in os.walk('%s/%s/data' % (T, name)) for x in xs if x.endswith('.dat'))


def main():
    store('A'); store('B')
    for n in STORES:
        until(lambda: http(f(n, '/'))[0] == 200 and http(d(n, '/'))[0] == 200, what='store ' + n)
    if HELP:
        for c in ('remote.configure', 'remote.mount', 'remote.cache', 'remote.uncache', 'remote.meta.sync', 'remote.unmount', 'remote.mount.buckets'):
            print('=====', c); print(shell('B', 'help ' + c)[1])
        print(shell('B', 'remote.configure -h')[1])
        return 0
    return body()


def chunks(name, path):
    code, body = http(f(name, path + '?metadata=true'))
    try: return len(json.loads(body).get('chunks') or [])
    except ValueError: return 'no entry (%s)' % code


def body():
    P = '/buckets/projects'
    contents = {}
    say('A: bucket made (http code)', http(d('A', '/projects'), data=b'', method='PUT')[0])
    for i in range(12):
        contents['file-%02d.bin' % i] = os.urandom(300000) + bytes([i])
        http(f('A', '%s/file-%02d.bin' % (P, i)), data=contents['file-%02d.bin' % i], method='PUT')
    say('A: bytes of content in its own folder', data_bytes('A'))
    say('B: bytes of content in its own folder, before the link', data_bytes('B'))

    # ---- a folder of B becomes a link to the bucket of A, through A's S3 door
    print(shell('B', 'remote.configure -name=storea -type=s3 -s3.access_key=any -s3.secret_key=any -s3.endpoint=http://%s:%d -s3.region=us-east-1' % (AH, STORES['A']['s3']))[1])
    print(shell('B', 'remote.mount -dir=%s -remote=storea/projects' % P)[1])
    code, listing = http(f('B', P + '/?limit=100'), headers={'Accept': 'application/json'})
    try: names = [e['FullPath'] for e in json.loads(listing).get('Entries') or []]
    except ValueError: names = listing[:200]
    say('B: names it lists in the linked folder', len(names) if isinstance(names, list) else names)
    say('B: pieces of content it holds for file-00, before any read', chunks('B', P + '/file-00.bin'))
    say('B: bytes of content in its own folder, linked, nothing read', data_bytes('B'))
    code, got = http(f('B', P + '/file-00.bin'), timeout=30)
    say('B: file-00 read through B gives the bytes of A', (code, got == contents['file-00.bin']))
    time.sleep(2)
    say('B: pieces of content it holds for file-00, after that read', chunks('B', P + '/file-00.bin'))

    # ---- take everything: B holds the content too
    print(shell('B', 'remote.cache -dir=%s' % P)[1][-400:])
    say('B: pieces it holds for file-05 after taking the folder', chunks('B', P + '/file-05.bin'))
    say('B: bytes of content in its own folder after taking the folder', data_bytes('B'))

    # ---- A away: is the taken copy usable on B?
    stop('store-A')
    code, got = http(f('B', P + '/file-05.bin'), timeout=30)
    say('A away: file-05 read through B', (code, got == contents['file-05.bin']))
    say('A away: a change saved on B (http code)', http(f('B', P + '/file-05.bin'), data=b'edited on B while A was away', method='PUT')[0])
    say('A away: a new file saved on B (http code)', http(f('B', P + '/new-on-b.txt'), data=b'made on B while A was away', method='PUT')[0])
    store('A')
    until(lambda: http(f('A', '/'))[0] == 200 and http(d('A', '/'))[0] == 200, what='store A back')
    until(lambda: http(f('A', P + '/file-01.bin'), timeout=30)[0] == 200, what='A to serve its files again')
    say('A back, nothing run yet: file-05 on A is still the original', http(f('A', P + '/file-05.bin'), timeout=30)[1] == contents['file-05.bin'])

    # ---- the edits go back: the program's own process that writes B's changes to A
    start('return', 'filer.remote.sync', '-filer=%s:%d' % (H, STORES['B']['filer']), '-dir=' + P)
    back = until(lambda: http(f('A', P + '/file-05.bin'))[1] == b'edited on B while A was away', seconds=60, what='the edit to reach A')
    say('edits made while A was away reach A once the return process runs', back)
    say('the new file made on B is on A', http(f('A', P + '/new-on-b.txt'))[1])
    http(f('B', P + '/file-06.bin'), data=b'edited on B, A present', method='PUT')
    say('an edit on B with A present reaches A', until(lambda: http(f('A', P + '/file-06.bin'))[1] == b'edited on B, A present', seconds=30, what='the second edit'))
    http(f('B', P + '/file-07.bin'), method='DELETE')
    say('a file taken away on B is taken away on A', until(lambda: http(f('A', P + '/file-07.bin'))[0] == 404, seconds=45, what='the delete'))
    say('  (what A answers for it, http code)', http(f('A', P + '/file-07.bin'))[0])

    # ---- A holds the original still (the read-only rule) while B has the copy
    say('A: rule, the folder may not be changed', shell('A', 'fs.configure -locationPrefix=%s/ -readOnly -apply' % P)[0])
    until(lambda: http(f('A', P + '/wait-%d.txt' % time.time()), data=b'w', method='PUT')[0] not in (200, 201), seconds=20, what='the rule to hold')
    say('held: a change on A by someone else (http code)', http(f('A', P + '/file-10.bin'), data=b'someone else', method='PUT')[0])
    http(f('B', P + '/file-10.bin'), data=b'edited on B while A holds the original', method='PUT')
    time.sleep(15)
    say('held: the edit of B has reached A after 15 seconds', http(f('A', P + '/file-10.bin'))[1][:40] == b'edited on B while A holds the original')
    say('held: B still gives its own edit', http(f('B', P + '/file-10.bin'))[1][:40])
    say('A: rule taken away', shell('A', 'fs.configure -locationPrefix=%s/ -delete -apply' % P)[0])
    say('released: the edit of B reaches A by itself', until(lambda: http(f('A', P + '/file-10.bin'))[1][:40] == b'edited on B while A holds the original', seconds=90, what='the held edit'))
    http(f('B', P + '/file-11.bin'), data=b'a later edit on B', method='PUT')
    say('released: a later edit on B reaches A', until(lambda: http(f('A', P + '/file-11.bin'))[1] == b'a later edit on B', seconds=45, what='the later edit'))

    # ---- a change on A while the copy is out
    http(f('A', P + '/file-08.bin'), data=b'changed on A meanwhile', method='PUT')
    time.sleep(3)
    say('a change on A, before B asks: what B gives for the file', http(f('B', P + '/file-08.bin'), timeout=30)[1][:30] == b'changed on A meanwhile')
    print(shell('B', 'remote.meta.sync -dir=%s' % P)[1][-300:])
    say('a change on A, after B asked for the names again: what B gives', http(f('B', P + '/file-08.bin'), timeout=30)[1][:30])
    print(shell('B', 'remote.cache -dir=%s' % P)[1][-200:])
    say('a change on A, after B took the folder again: what B gives', http(f('B', P + '/file-08.bin'), timeout=30)[1][:30])
    # both changed the same file
    http(f('A', P + '/file-09.bin'), data=b'A wrote this', method='PUT')
    http(f('B', P + '/file-09.bin'), data=b'B wrote this', method='PUT')
    time.sleep(6)
    say('both changed one file: what A holds / what B gives', (http(f('A', P + '/file-09.bin'))[1][:20], http(f('B', P + '/file-09.bin'))[1][:20]))

    # ---- drop the copy: B keeps the names, not the content
    stop('return')
    print(shell('B', 'remote.uncache -dir=%s' % P)[1][-400:])
    say('B: pieces it holds for file-01 after dropping the copy', chunks('B', P + '/file-01.bin'))
    say('B: pieces it holds for file-05 (edited on B, returned) after dropping', chunks('B', P + '/file-05.bin'))
    say('A: file-01 is still whole on A', http(f('A', P + '/file-01.bin'), timeout=30)[1] == contents['file-01.bin'])
    code, got = http(f('B', P + '/file-01.bin'), timeout=30)
    say('B: file-01 read through B again (fetched from A again)', (code, got == contents['file-01.bin']))
    print(shell('B', 'remote.unmount -dir=%s' % P)[1][-300:])
    say('link taken away: B has the folder', http(f('B', P + '/file-01.bin'))[0])
    say('link taken away: A still has file-01 whole', http(f('A', P + '/file-01.bin'), timeout=30)[1] == contents['file-01.bin'])
    return 0


try:
    code = main()
finally:
    for name in list(procs): stop(name)
    for left in set(glob.glob('/tmp/seaweedfs-*')) - BEFORE: os.unlink(left)
    json.dump(facts, open(T + '/facts.json', 'w'), indent=1, default=str)
    print('work folder: ' + T)
sys.exit(code)
