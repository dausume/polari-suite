#!/usr/bin/env python3
"""Distro-cache integrity fixtures; fake curl, no apt/container/network access."""
import hashlib
import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path
import tempfile
import unittest
from unittest import mock

SPEC=importlib.util.spec_from_file_location('offline_apt_integrity',Path(__file__).with_name('offline-apt-integrity.py'))
MODULE=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(MODULE)


class DistroIntegrity(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name);self.cache=self.root/'cache';self.cache.mkdir()
        self.output=self.root/'output';self.output.mkdir();self.bin=self.root/'bin';self.bin.mkdir()
        self.remote=self.root/'remote';self.remote.write_bytes(b'trusted distro bytes')
        self.calls=self.root/'calls'
        curl=self.bin/'curl'
        curl.write_text('''#!/usr/bin/python3
import json,os,pathlib,sys
args=sys.argv[1:]
with open(os.environ['CALLS'],'a') as out:out.write(json.dumps(args)+'\\n')
if os.environ.get('CURL_FAIL'):sys.exit(22)
pathlib.Path(args[args.index('--output')+1]).write_bytes(pathlib.Path(os.environ['REMOTE']).read_bytes())
''');curl.chmod(0o755)
        self.environment=mock.patch.dict(os.environ,PATH=str(self.bin)+':'+os.environ['PATH'],CALLS=str(self.calls),REMOTE=str(self.remote))
        self.environment.start();self.addCleanup(self.environment.stop)
        self.content=self.remote.read_bytes();self.digest=hashlib.sha256(self.content).hexdigest()
        self.record="'https://archive.ubuntu.test/pool/package_1_all.deb' package_1_all.deb %d SHA256:%s"%(len(self.content),self.digest)
        self.entry=MODULE.inventory(self.record)[0]
    def test_signed_apt_record_keeps_sha256_size_and_legacy_cache_name(self):
        record="'https://archive.ubuntu.test/pool/package_1%%2b%%7e1_all.deb' package_1+~1_all.deb %d SHA256:%s"%(len(self.content),self.digest)
        entry=MODULE.inventory('Reading package lists...\n'+record+'\n')[0]
        self.assertEqual(entry['sha256'],self.digest);self.assertEqual(entry['size'],len(self.content))
        self.assertEqual(entry['legacyCacheFile'],'package_1%2b%7e1_all.deb')
    def test_absent_weak_or_ambiguous_hash_metadata_refused(self):
        for record in (self.record.rsplit(' ',1)[0],self.record.replace('SHA256:','MD5Sum:'),self.record+'\n'+self.record.replace(self.digest,'0'*64)):
            with self.subTest(record=record):
                with self.assertRaises(ValueError):MODULE.inventory(record)
    def test_unsafe_archive_path_refused(self):
        with self.assertRaises(ValueError):MODULE.inventory(self.record.replace(' package_1_all.deb ',' ../package_1_all.deb '))
    def test_inventory_and_fetch_cli_roundtrip(self):
        records=self.root/'records';records.write_text(self.record+'\n')
        data=self.root/'inventory.json';uris=self.root/'uris.txt'
        helper=Path(__file__).with_name('offline-apt-integrity.py')
        result=subprocess.run([sys.executable,str(helper),'inventory','--records',str(records),'--json',str(data),'--uris',str(uris)],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(uris.read_text(),self.entry['uri']+'\n')
        (self.cache/self.entry['file']).write_bytes(self.content)
        result=subprocess.run([sys.executable,str(helper),'fetch','--inventory',str(data),'--output',str(self.output),'--cache',str(self.cache)],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('cached_bytes='+str(len(self.content)),result.stdout)
        self.assertFalse(self.calls.exists())
    def test_valid_cache_reused_without_curl(self):
        (self.cache/self.entry['file']).write_bytes(self.content)
        with mock.patch.dict(os.environ,CURL_FAIL='1'):
            report=MODULE.acquire([self.entry],self.output,self.cache)
        self.assertEqual(report,{'cached_bytes':len(self.content),'fetched_bytes':0})
        self.assertEqual((self.output/self.entry['file']).read_bytes(),self.content)
        self.assertFalse(self.calls.exists())
    def test_escaped_legacy_cache_reused_only_after_verification(self):
        record="'https://archive.ubuntu.test/pool/package_1%%2b%%7e1_all.deb' package_1+~1_all.deb %d SHA256:%s"%(len(self.content),self.digest)
        entry=MODULE.inventory(record)[0];legacy=self.cache/entry['legacyCacheFile'];legacy.write_bytes(self.content)
        report=MODULE.acquire([entry],self.output,self.cache)
        self.assertEqual(report['cached_bytes'],len(self.content));self.assertEqual(legacy.read_bytes(),self.content)
        self.assertFalse(self.calls.exists())
    def test_corrupt_same_size_cache_rejected_then_verified_download_repairs_it(self):
        cached=self.cache/self.entry['file'];cached.write_bytes(b'X'*len(self.content))
        untouched=self.cache/'unrelated-valid.deb';untouched.write_bytes(b'preserved')
        report=MODULE.acquire([self.entry],self.output,self.cache)
        self.assertEqual(report,{'cached_bytes':0,'fetched_bytes':len(self.content)})
        self.assertEqual(cached.read_bytes(),self.content);self.assertEqual((self.output/self.entry['file']).read_bytes(),self.content)
        self.assertEqual(untouched.read_bytes(),b'preserved');self.assertTrue(self.calls.exists())
    def test_corrupt_download_never_enters_cache_or_output(self):
        self.remote.write_bytes(b'X'*len(self.content))
        with self.assertRaisesRegex(ValueError,'download rejected'):MODULE.acquire([self.entry],self.output,self.cache)
        self.assertFalse((self.output/self.entry['file']).exists());self.assertFalse((self.cache/self.entry['file']).exists())
        self.assertFalse(list(self.cache.glob('*.part')))
    def test_bad_cache_preserved_when_replacement_download_also_invalid(self):
        cached=self.cache/self.entry['file'];cached.write_bytes(b'bad cached bytes')
        self.remote.write_bytes(b'X'*len(self.content))
        with self.assertRaises(ValueError):MODULE.acquire([self.entry],self.output,self.cache)
        self.assertEqual(cached.read_bytes(),b'bad cached bytes');self.assertFalse((self.output/self.entry['file']).exists())
    def test_incorrect_download_size_refused_without_cache(self):
        self.remote.write_bytes(self.content+b'extra')
        with self.assertRaises(ValueError):MODULE.acquire([self.entry],self.output)
        self.assertFalse((self.output/self.entry['file']).exists())
    def test_failed_transfer_does_not_publish_partial_files(self):
        with mock.patch.dict(os.environ,CURL_FAIL='1'):
            with self.assertRaises(subprocess.CalledProcessError):MODULE.acquire([self.entry],self.output,self.cache)
        self.assertEqual(list(self.output.iterdir()),[]);self.assertEqual(list(self.cache.iterdir()),[])
    def test_cache_change_during_copy_is_caught_before_output_commit(self):
        (self.cache/self.entry['file']).write_bytes(self.content)
        original=MODULE.shutil.copyfile
        def corrupt_copy(source,destination):
            result=original(source,destination);Path(destination).write_bytes(b'X'*len(self.content));return result
        with mock.patch.object(MODULE.shutil,'copyfile',side_effect=corrupt_copy):
            with self.assertRaisesRegex(ValueError,'copied archive failed'):MODULE.acquire([self.entry],self.output,self.cache)
        self.assertFalse((self.output/self.entry['file']).exists())


if __name__=='__main__':unittest.main()
