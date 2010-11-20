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
        self.tempfile.seek(0)
        self.popen = subprocess.Popen(
                [os.path.join('target', 'xmpedit'), self.tempfile.name],
                env=dict(os.environ.items() + [
                    ('G_DEBUG', 'fatal_criticals'),
                    ('G_SLICE', 'debug-blocks'),
                    ('GNOME_DISABLE_CRASH_DIALOG', '1')
                ]))

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
    
    def assert_image_unmodified(self, image_filename):
        self.tempfile.seek(0)
        assert self.tempfile.read() == open(os.path.join('testdata', image_filename)).read(), 'Image should be unmodified'

    def get_window(self):
        root = Xlib.display.Display().screen().root # XXX multiple screens?
        for child in root.query_tree().children:
            if child.get_wm_class() is not None and 'xmpedit' in child.get_wm_class():
                return child
    
    def close_window(self):
        window = self.get_window()
        assert window is not None, "Where'd the window go?"
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
        
    def test_do_nothing(self):
        xmpedit = dogtail.tree.Root().application('xmpedit')
        window = xmpedit.child(roleName='frame')
        self.close_window()
        self.assert_stopped()
        self.assert_image_unmodified('24-06-06_1449.jpg')
    
    def test_close_without_saving(self):
        xmpedit = dogtail.tree.Root().application('xmpedit')
        window = xmpedit.child(roleName='frame')
        pe, = [child for child in window.child('Image properties').children
                if child.name.splitlines()[0] == 'Description'] # ugh
        pe.select()
        entry = window.child(roleName='ROLE_TEXT', label='Description')
        entry.grabFocus()
        entry.text = 'new description'
        lang = window.child(roleName='ROLE_TEXT', label='Language:')
        lang.text = 'en'
        self.close_window()
        alert = xmpedit.child(roleName='alert')
        self.assertEquals(alert.child(roleName='label').name,
                'Your changes to image "%s" have not been saved.\n\nSave changes before closing?'
                % os.path.basename(self.tempfile.name))
        alert.button('Close without saving').doAction('click')
        self.assert_stopped()
        self.assert_image_unmodified('24-06-06_1449.jpg')
            
    def test_edit_then_revert(self):
        xmpedit = dogtail.tree.Root().application('xmpedit')
        window = xmpedit.child(roleName='frame')
        pe, = [child for child in window.child('Image properties').children
                if child.name.splitlines()[0] == 'Description'] # ugh
        pe.select()
        entry = window.child(roleName='ROLE_TEXT', label='Description')
        entry.grabFocus()
        entry.text = 'new description'
        lang = window.child(roleName='ROLE_TEXT', label='Language:')
        lang.text = 'en'
        assert window.button('Revert').sensitive
        window.button('Revert').doAction('click')
        entry = window.child(roleName='ROLE_TEXT', label='Description')
        self.assertEquals(entry.text, 'Edward Scissorhands stencil graffiti '
                'on the wall of John Hines building.')
        lang = window.child(roleName='ROLE_TEXT', label='Language:')
        self.assertEquals(lang.text, 'x-default')
        self.close_window()
        self.assert_stopped()
        self.assert_image_unmodified('24-06-06_1449.jpg')

    def test_update_description(self):
        xmpedit = dogtail.tree.Root().application('xmpedit')
        window = xmpedit.child(roleName='frame')
        pe, = [child for child in window.child('Image properties').children
                if child.name.splitlines()[0] == 'Description'] # ugh
        pe.select()
        entry = window.child(roleName='ROLE_TEXT', label='Description')
        entry.grabFocus()
        entry.text = 'new description'
        lang = window.child(roleName='ROLE_TEXT', label='Language:')
        lang.text = 'en'
        assert window.button('Save').sensitive
        window.button('Save').doAction('click')
        self.close_window()
        self.assert_stopped()
        xmp = extract_xmp(self.tempfile.name)
        self.assertEquals(len(xmp), 2675)
        self.assertEquals(extract_xmp(self.tempfile.name),
                u'''<?xpacket begin="\ufeff" id="W5M0MpCehiHzreSzNTczkc9d"?><x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="xmpedit 0.0-dev"><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description rdf:about=""><Iptc4xmlCore:Location xmlns:Iptc4xmlCore="http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/">UQ St Lucia</Iptc4xmlCore:Location><dc:description xmlns:dc="http://purl.org/dc/elements/1.1/" xml:lang="en">new description</dc:description></rdf:Description></rdf:RDF></x:xmpmeta>''' + ' ' * 2179 + '''<?xpacket end="w"?>''')

if __name__ == '__main__':
    unittest.main()
