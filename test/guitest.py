#!/usr/bin/env python

import sys
import os
import time
import struct
import tempfile
import subprocess
import Xlib.display
import dogtail.tree
import unittest

def extract_xmp(path):
    popen = subprocess.Popen([
            os.path.join('target', 'printxmp'), path],
            stdout=subprocess.PIPE)
    stdout, stderr = popen.communicate()
    assert popen.returncode == 0
    return stdout.decode('utf8')

class XmpeditTestCase(unittest.TestCase):

    def start(self, image_filename):
        self.tempfile = tempfile.NamedTemporaryFile()
        self.tempfile.write(open(os.path.join('testdata', image_filename)).read())
        self.tempfile.flush()
        self.popen = subprocess.Popen(
                [os.path.join('target', 'xmpedit'), self.tempfile.name])

    def stop(self):
        if self.popen.returncode is None:
            print 'Terminating process under test'
            self.popen.terminate()
            self.popen.wait()

    def assert_stopped(self):
        for _ in range(3):
            if self.popen.poll() is not None:
                assert self.popen.returncode == 0
                return
            time.sleep(1)
        assert False, 'Process did not end'

    def get_window(self):
        root = Xlib.display.Display().screen().root # XXX multiple screens?
        for child in root.query_tree().children:
            if child.get_wm_class() is not None and 'xmpedit' in child.get_wm_class():
                return child
    
    def close_window(self):
        window = self.get_window()
        WM_PROTOCOLS = window.display.get_atom('WM_PROTOCOLS')
        WM_DELETE_WINDOW = window.display.get_atom('WM_DELETE_WINDOW')
        assert WM_DELETE_WINDOW in window.get_wm_protocols()
        event = Xlib.protocol.event.ClientMessage(window=window, client_type=WM_PROTOCOLS,
                data=(32, struct.pack('=lllll', WM_DELETE_WINDOW, 0, 0, 0, 0)))
        window.send_event(event)
        window.display.flush()
    
class Test(XmpeditTestCase):

    def setUp(self):
        self.start('24-06-06_1449.jpg')

    def tearDown(self):
        self.stop()
        
    def test_roundtrip(self):
        xmpedit = dogtail.tree.Root().application('xmpedit')
        window = xmpedit.child(roleName='frame')
        time.sleep(0.5)
        self.close_window()
        self.assert_stopped()
        xmp = extract_xmp(self.tempfile.name)
        self.assertEquals(len(xmp), 2675) # 
        self.assertEquals(extract_xmp(self.tempfile.name),
                u'''<?xpacket begin="\ufeff" id="W5M0MpCehiHzreSzNTczkc9d"?><x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="xmpedit 0.0-dev"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description rdf:about=""><Iptc4xmlCore:Location xmlns:Iptc4xmlCore="http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/">UQ St Lucia</Iptc4xmlCore:Location><dc:description xmlns:dc="http://purl.org/dc/elements/1.1/"><rdf:Alt><rdf:li xml:lang="x-default">Edward Scissorhands stencil graffiti on the wall of John Hines building.</rdf:li></rdf:Alt></dc:description></rdf:Description></rdf:RDF></x:xmpmeta>''' + ' ' * 2079 + '''<?xpacket end="w"?>''')

if __name__ == '__main__':
    unittest.main()
