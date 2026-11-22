#!/usr/bin/env python3
"""A by-hand look at the file pool's mechanics, on this machine only: plain processes of the pinned file store
program, loopback addresses, a temporary folder.  Two made-up machines (rack machine-a, rack machine-b), three
made-up partitions.  Nothing here is on the isle or in Docker.  Outside the temporary folder the program leaves only its socket files in
/tmp, and those are removed at the end.

usage: pool-proof.py <weed program> <folder to work in> [mount]
"""
import glob
import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

W, BASE = sys.argv[1], sys.argv[2]
MOUNT = 'mount' in sys.argv[3:]
T = tempfile.mkdtemp(dir=BASE, prefix='pool-proof-')
H = '127.0.0.1'
MASTER, FILER, S3 = 23333, 28888, 28333
PARTS = {'a1': (28081, 'machine-a', ''), 'b1': (28082, 'machine-b', ''), 'a2': (28083, 'machine-a', 'assets')}
procs, facts = {}, []
BEFORE = set(glob.glob('/tmp/seaweedfs-*'))      # the program puts its socket files there, whatever it is told


def say(what, value):
    facts.append((what, value))
    print('%-64s %s' % (what, value), flush=True)


def start(name, *args):
    log = open('%s/%s.log' % (T, name), 'a')
    procs[name] = subprocess.Popen([W] + list(args), stdout=log, stderr=log, cwd=T)


def stop(name):
    p = procs.pop(name, None)
    if p is None: return
    p.send_signal(signal.SIGTERM)
    try: p.wait(timeout=20)
    except subprocess.TimeoutExpired:
        p.kill(); p.wait()


def http(url, data=None, method=None, timeout=8, headers=None):
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
    say('TIMED OUT waiting for ' + what, '')
    return False


def volume(name):
    port, rack, disk = PARTS[name]
    folder = '%s/part-%s/isle-pool' % (T, name)
    os.makedirs(folder, exist_ok=True)
    args = ['volume', '-ip=' + H, '-port=%d' % port, '-dir=' + folder, '-max=30', '-master=%s:%d' % (H, MASTER),
            '-rack=' + rack, '-dataCenter=isle']
    if disk: args.append('-disk=' + disk)
    start('volume-' + name, *args)


def nodes():
    code, body = http('http://%s:%d/dir/status' % (H, MASTER))
    found = []
    for dc in (json.loads(body).get('Topology', {}).get('DataCenters') or []):
        for rack in dc.get('Racks') or []:
            for node in rack.get('DataNodes') or []:
                found.append(node.get('Url'))
    return sorted(found)


def shell(command):
    done = subprocess.run([W, 'shell', '-master=%s:%d' % (H, MASTER), '-filer=%s:%d' % (H, FILER)], input=command + '\nexit\n',
                          capture_output=True, text=True, timeout=60, cwd=T)
    return done.returncode, (done.stdout + done.stderr).strip()


def put(path, content):
    return http('http://%s:%d%s' % (H, FILER, path), data=content, method='PUT')[0]


def get(path):
    return http('http://%s:%d%s' % (H, FILER, path))


def where(path):
    """The ports of the storage processes that hold the content of one file."""
    code, body = get(path + '?metadata=true')
    ports = set()
    for chunk in json.loads(body).get('chunks') or []:
        vid = chunk['file_id'].split(',')[0]
        code, found = http('http://%s:%d/dir/lookup?volumeId=%s' % (H, MASTER, vid))
        for loc in json.loads(found).get('locations') or []:
            ports.add(int(loc['url'].rsplit(':', 1)[1]))
    return sorted(ports)


def read_all(paths, contents):
    good = [p for p in paths if get(p) == (200, contents[p])]
    return len(good), len(paths)


def main():
    start('master', 'master', '-ip=' + H, '-port=%d' % MASTER, '-mdir=%s/index' % T, '-peers=none', '-volumeSizeLimitMB=64',
          '-defaultReplication=000')
    os.makedirs(T + '/index', exist_ok=True)
    until(lambda: http('http://%s:%d/cluster/status' % (H, MASTER))[0] == 200, what='the index')
    volume('a1'); volume('b1')
    until(lambda: len(nodes()) == 2, what='two storage processes')
    os.makedirs(T + '/names', exist_ok=True)
    start('filer', 'filer', '-ip=' + H, '-port=%d' % FILER, '-master=%s:%d' % (H, MASTER), '-defaultStoreDir=%s/names' % T,
          '-s3', '-s3.port=%d' % S3, '-s3.port.iceberg=0', '-s3.port.lance=0')
    until(lambda: get('/')[0] == 200, what='the list of file names')
    say('storage processes the index knows', nodes())

    # ---- one copy
    contents, one = {}, []
    for i in range(60):
        path = '/buckets/one/file-%02d.bin' % i
        contents[path] = os.urandom(2000) + bytes([i])
        code = put(path, contents[path]); one.append(path)
        if code not in (200, 201): say('write refused', (path, code))
    held = {p: where(p) for p in one}
    on_a = [p for p in one if held[p] == [PARTS['a1'][0]]]
    on_b = [p for p in one if held[p] == [PARTS['b1'][0]]]
    say('one copy: files held by a1 only / by b1 only / other', (len(on_a), len(on_b), len(one) - len(on_a) - len(on_b)))
    stop('volume-b1')
    until(lambda: len(nodes()) == 1, what='the index to see b1 gone')
    say('b1 away: storage processes the index knows', nodes())
    say('b1 away: files of a1 that read back whole', '%d of %d' % read_all(on_a, contents))
    say('b1 away: files of b1 that read back whole', '%d of %d' % read_all(on_b, contents))
    if on_b: say('b1 away: answer for one file of b1', (get(on_b[0])[0], get(on_b[0])[1][:120]))
    new = []
    for i in range(10):
        path = '/buckets/one/while-away-%02d.bin' % i
        contents[path] = os.urandom(1500)
        code = put(path, contents[path]); new.append((path, code))
    say('b1 away: new one-copy files written', '%d of %d' % (len([1 for p, c in new if c in (200, 201)]), len(new)))
    volume('b1')
    until(lambda: len(nodes()) == 2, what='b1 back')
    until(lambda: read_all(on_b, contents)[0] == len(on_b), seconds=30, what='the files of b1 to be back')
    say('b1 back: every one-copy file reads back whole', '%d of %d' % read_all(one, contents))

    # ---- two copies on two machines, for one file space only
    say('rule: /buckets/two/ keeps two copies on two machines', shell('fs.configure -locationPrefix=/buckets/two/ -replication=010 -apply')[0])
    two = []
    for i in range(20):
        path = '/buckets/two/file-%02d.bin' % i
        contents[path] = os.urandom(2000)
        code = put(path, contents[path]); two.append(path)
        if code not in (200, 201): say('write refused', (path, code))
    say('two copies: files held by both a1 and b1', '%d of %d' % (len([p for p in two if where(p) == [PARTS['a1'][0], PARTS['b1'][0]]]), len(two)))
    stop('volume-b1')
    until(lambda: len(nodes()) == 1, what='the index to see b1 gone')
    say('b1 away: two-copy files that read back whole', '%d of %d' % read_all(two, contents))
    began = time.time()
    code, body = http('http://%s:%d/buckets/two/while-away.bin' % (H, FILER), data=b'x' * 500, method='PUT', timeout=45)
    say('b1 away: a new two-copy file is written (http code, seconds, answer)', (code, round(time.time() - began, 1), body[:160]))
    volume('b1')
    until(lambda: len(nodes()) == 2, what='b1 back')

    # ---- a partition's label decides which file space it holds
    volume('a2')
    until(lambda: len(nodes()) == 3, what='a2')
    say('rule: /buckets/tagged/ goes to partitions labelled assets', shell('fs.configure -locationPrefix=/buckets/tagged/ -disk=assets -apply')[0])
    tagged = []
    for i in range(20):
        path = '/buckets/tagged/file-%02d.bin' % i
        contents[path] = os.urandom(2000)
        code = put(path, contents[path]); tagged.append(path)
        if code not in (200, 201): say('write refused', (path, code))
    say('labelled: files held by a2 only', '%d of %d' % (len([p for p in tagged if where(p) == [PARTS['a2'][0]]]), len(tagged)))
    more = []
    for i in range(30):
        path = '/buckets/one/later-%02d.bin' % i
        contents[path] = os.urandom(2000); put(path, contents[path]); more.append(path)
    say('unlabelled files that landed on the labelled partition', len([p for p in more if PARTS['a2'][0] in where(p)]))
    say('folders of the three partitions hold data files', {n: len([f for f in os.listdir('%s/part-%s/isle-pool' % (T, n)) if f.endswith('.dat')]) for n in PARTS})

    # ---- the same files through the S3 door (no keys configured here: the door is open in this trial)
    code, body = http('http://%s:%d/one/file-00.bin' % (H, S3))
    say('S3 door gives the same bytes for one/file-00.bin', (code, body == contents['/buckets/one/file-00.bin']))

    # ---- holding an original still while a copy of it is out (9.7): a rule that makes one folder read-only
    F, D = 'http://%s:%d' % (H, FILER), 'http://%s:%d' % (H, S3)
    for name in ('board.kicad_pcb', 'probe-a.txt', 'probe-b.txt', 'probe-c.txt'): put('/buckets/one/taken/' + name, b'the original')
    say('rule: /buckets/one/taken/ may not be changed', shell('fs.configure -locationPrefix=/buckets/one/taken/ -readOnly -apply')[0])
    until(lambda: put('/buckets/one/taken/wait-%d.txt' % time.time(), b'w') not in (200, 201), seconds=20, what='the rule to hold')
    say('held: a change through the names index (http code)', put('/buckets/one/taken/board.kicad_pcb', b'changed by someone else'))
    say('held: a change through the S3 door (http code)', http(D + '/one/taken/board.kicad_pcb', data=b'changed through S3', method='PUT')[0])
    say('held: a new file in the folder (http code)', put('/buckets/one/taken/new.txt', b'new'))
    say('held: the original still reads, unchanged', get('/buckets/one/taken/board.kicad_pcb') == (200, b'the original'))
    say('held: taking a file away through the names index (http code, then a read)', (http(F + '/buckets/one/taken/probe-a.txt', method='DELETE')[0], get('/buckets/one/taken/probe-a.txt')[0]))
    say('held: taking a file away through the S3 door (http code, then a read)', (http(D + '/one/taken/probe-b.txt', method='DELETE')[0], get('/buckets/one/taken/probe-b.txt')[0]))
    say('held: a file given another name inside the folder (http code, old name, new name)', (http(F + '/buckets/one/taken/renamed.txt?mv.from=/buckets/one/taken/probe-c.txt', data=b'', method='POST')[0], get('/buckets/one/taken/probe-c.txt')[0], get('/buckets/one/taken/renamed.txt')[0]))
    say('held: a file beside the folder can still be changed (http code)', put('/buckets/one/beside.txt', b'free'))
    say('rule taken away', shell('fs.configure -locationPrefix=/buckets/one/taken/ -delete -apply')[0])
    until(lambda: put('/buckets/one/taken/board.kicad_pcb', b'the edits, returned') in (200, 201), seconds=20, what='the rule to go')
    say('released: the edits are written to the original', get('/buckets/one/taken/board.kicad_pcb')[1])

    # ---- the S3 door's own hold on one object (a bucket made with object lock)
    say('bucket made with object lock (http code)', http(D + '/held', data=b'', method='PUT', headers={'x-amz-bucket-object-lock-enabled': 'true'})[0])
    say('object written (http code)', http(D + '/held/board.kicad_pcb', data=b'the original', method='PUT')[0])
    hold = b'<LegalHold xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Status>%s</Status></LegalHold>'
    say('hold put on the object (http code, answer)', tuple(x if isinstance(x, int) or x is None else x[:120] for x in http(D + '/held/board.kicad_pcb?legal-hold', data=hold % b'ON', method='PUT')))
    say('hold: a change through the S3 door (http code)', http(D + '/held/board.kicad_pcb', data=b'changed through S3', method='PUT')[0])
    say('hold: what the name gives now', http(D + '/held/board.kicad_pcb')[1][:40])
    say('hold: a change through the names index (http code)', put('/buckets/held/board.kicad_pcb', b'changed through the names index'))
    say('hold: what the name gives now', http(D + '/held/board.kicad_pcb')[1][:40])
    code, body = http(D + '/held?versions')
    say('hold: versions the door lists for the name', (code, body.count(b'<Version>'), body.count(b'<DeleteMarker>')))
    say('hold: taking the object away through the S3 door (http code, then a read)', (http(D + '/held/board.kicad_pcb', method='DELETE')[0], http(D + '/held/board.kicad_pcb')[0]))

    if MOUNT: mount(contents, one)
    return 0


def mount(contents, one):
    folder, cache = T + '/mnt', T + '/cache'
    os.makedirs(folder); os.makedirs(cache)
    start('mount', 'mount', '-filer=%s:%d' % (H, FILER), '-dir=' + folder, '-filer.path=/buckets/one', '-cacheDir=' + cache,
          '-cacheCapacityMB=16', '-allowOthers=false', '-volumeServerAccess=filerProxy')
    if not until(lambda: os.path.ismount(folder), what='the mount'): return
    names = sorted(os.listdir(folder))
    say('mounted folder lists the files of the file space', len(names))
    first = one[0]
    say('a file read through the folder has the same bytes', open(folder + '/' + os.path.basename(first), 'rb').read() == contents[first])
    with open(folder + '/saved-in-the-folder.kicad_pcb', 'wb') as f: f.write(b'(kicad_pcb made-up)\n' * 200)
    until(lambda: get('/buckets/one/saved-in-the-folder.kicad_pcb')[0] == 200, seconds=15, what='the saved file')
    say('a file saved in the folder is in the pool', get('/buckets/one/saved-in-the-folder.kicad_pcb')[1] == b'(kicad_pcb made-up)\n' * 200)
    # a save from elsewhere while the folder is mounted
    put('/buckets/one/' + os.path.basename(first), b'changed elsewhere')
    seen = until(lambda: open(folder + '/' + os.path.basename(first), 'rb').read() == b'changed elsewhere', seconds=20, what='the change from elsewhere')
    say('a change made elsewhere shows in the folder', seen)
    # two saves of one file: one in the folder, one elsewhere, the later one stays
    with open(folder + '/both.txt', 'wb') as f: f.write(b'saved in the folder')
    time.sleep(1)
    put('/buckets/one/both.txt', b'saved elsewhere, later')
    time.sleep(2)
    say('two saves of one file: what the pool holds', get('/buckets/one/both.txt')[1])
    # the read-only rule, as the mounted folder sees it
    for name in ('keep.txt', 'gone.txt', 'old-name.txt'): put('/buckets/one/held/' + name, b'the original')
    until(lambda: len(os.listdir(folder + '/held')) == 3, seconds=20, what='the held folder in the mount')
    say('rule: /buckets/one/held/ may not be changed', shell('fs.configure -locationPrefix=/buckets/one/held/ -readOnly -apply')[0])
    until(lambda: put('/buckets/one/held/wait-%d.txt' % time.time(), b'w') not in (200, 201), seconds=20, what='the rule to hold')
    def attempt(action):
        try: action(); return 'done'
        except OSError as e: return 'refused: ' + (e.strerror or str(e))
    def save():
        with open(folder + '/held/keep.txt', 'wb') as f: f.write(b'changed in the folder')
    say('held, in the folder: a save over the original', attempt(save))
    time.sleep(3)
    say('held, in the folder: what the pool holds for it afterwards', get('/buckets/one/held/keep.txt'))
    say('held, in the folder: what the folder shows for it afterwards', open(folder + '/held/keep.txt', 'rb').read()[:40])
    say('held, in the folder: taking a file away', attempt(lambda: os.remove(folder + '/held/gone.txt')))
    time.sleep(2)
    say('held, in the folder: is that file still in the pool (http code)', get('/buckets/one/held/gone.txt')[0])
    say('held, in the folder: another name for a file', attempt(lambda: os.rename(folder + '/held/old-name.txt', folder + '/held/new-name.txt')))
    time.sleep(2)
    say('held, in the folder: old name / new name in the pool (http codes)', (get('/buckets/one/held/old-name.txt')[0], get('/buckets/one/held/new-name.txt')[0]))
    shell('fs.configure -locationPrefix=/buckets/one/held/ -delete -apply')
    say('cache folder size in bytes after use', sum(os.path.getsize(os.path.join(d, f)) for d, _, fs in os.walk(cache) for f in fs))
    # the index of names goes away: is the folder still usable?
    name = os.path.basename(one[1])
    open(folder + '/' + name, 'rb').read()      # read once, so it is in the cache
    stop('filer')
    try:
        done = subprocess.run(['timeout', '15', 'cat', folder + '/' + name], capture_output=True, timeout=25)
        say('names index away: a file read before, read again', ('exit %d' % done.returncode, done.stdout == contents[one[1]]))
    except subprocess.TimeoutExpired:
        say('names index away: a file read before, read again', 'no answer in 25 s')
    try:
        done = subprocess.run(['timeout', '15', 'cat', folder + '/' + os.path.basename(one[40])], capture_output=True, timeout=25)
        say('names index away: a file not read before', 'exit %d' % done.returncode)
    except subprocess.TimeoutExpired:
        say('names index away: a file not read before', 'no answer in 25 s')
    stop('mount')
    if os.path.ismount(folder):
        subprocess.run(['fusermount', '-u', '-z', folder], capture_output=True)
    say('folder unmounted at the end', not os.path.ismount(folder))


try:
    code = main()
finally:
    for name in list(procs): stop(name)
    folder = T + '/mnt'
    if os.path.ismount(folder): subprocess.run(['fusermount', '-u', '-z', folder], capture_output=True)
    for left in set(glob.glob('/tmp/seaweedfs-*')) - BEFORE: os.unlink(left)
    json.dump(facts, open(T + '/facts.json', 'w'), indent=1, default=str)
    print('work folder: ' + T)
sys.exit(code)
