import json
import os
import subprocess
import sys
import time

class Dylib:
    def __init__(self, filename):
        self.filename = filename
        self.dllname = os.path.join('out', os.path.basename(filename))[:-4] + '.dll'
        self.mtime = os.path.getmtime(self.filename)

def get_dylibs():
    data = []
    for root, _, files in os.walk('.'):
        for basename in files:
            filename = os.path.join(root, basename)
            if basename.endswith('.nim') and 'defineSystem:' in open(filename).read():
                data.append(Dylib(filename))
    return data

def remove(dylib):
    print '    Clearing {}...'.format(dylib.dllname)
    if os.path.isfile(dylib.dllname):
        os.remove(dylib.dllname)

def build(dylib):
    sys.stdout.flush()
    subprocess.check_call([
        'nim', 'c', '--app:lib', '--gc:none', '--nimcache:nimcache',
        '-o:' + dylib.dllname,
        dylib.filename
    ])
    dylib.mtime = os.path.getmtime(dylib.filename)

def move(dylib):
    oldname = dylib.dllname + "_old"
    if os.path.isfile(oldname):
        os.remove(oldname)
    if os.path.isfile(dylib.dllname):
        os.rename(dylib.dllname, oldname)

def removeOld(dylib):
    os.remove(dylib.dllname + "_old")

clear = '--clear' in sys.argv
dylibs = get_dylibs()

if clear:
    print "Clearing all .dlls..."
    for d in dylibs:
        remove(d)

print "Watching known dylib files..."
while True:
    built = []
    for d in dylibs:
        if not os.path.isfile(d.dllname) or os.path.getmtime(d.filename) != d.mtime:
            print 'Rebuilding ' + d.filename
            move(d)
            build(d)
    if built:
        time.sleep(5)
        for d in built:
            removeOld(d)
    time.sleep(0.2)
