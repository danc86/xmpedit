xmpedit
=======

xmpedit is a GTK+ editor for metadata embedded in images using the 
[XMP](http://www.adobe.com/devnet/xmp.html) format. It is written in 
[Vala](http://live.gnome.org/Vala) and released under the
[GPLv2](http://www.gnu.org/licenses/gpl-2.0.html).


Building xmpedit
----------------

xmpedit depends on the following packages:

* [GTK+](http://www.gtk.org/) (and its various dependencies, particularly GLib)
* [Libgee](http://live.gnome.org/Libgee)
* [Libxml2](http://xmlsoft.org/)
* [libsoup](http://live.gnome.org/LibSoup), although this dependency should really go away
* [Exiv2](http://www.exiv2.org/)

The following additional dependencies are required to build xmpedit:

* [Vala](http://live.gnome.org/Vala) version 0.11.1 or higher
* A C/C++ compiler (only tested with gcc)
* Python

Included in xmpedit are some automated GUI tests to verify its behaviour. 
Running these requires the following packages:

* [dogtail](https://fedorahosted.org/dogtail/)
* [Python X library](http://python-xlib.sourceforge.net/)

xmpedit uses a custom build script written in Python. To build the 
program, invoke `./build` from the root of the source tree. An executable 
will be produced in `target/xmpedit` if all goes well.

Invoke `./build -t` to run all tests.
