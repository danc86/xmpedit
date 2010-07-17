
import os
env = Environment(CFLAGS=os.environ.get('CFLAGS', '').split() + ['-Wall', '-ggdb'])
env['CXXFLAGS'] = env['CFLAGS']
env.ParseFlags('-I/usr/include/boost-1_42 -L/usr/lib/boost-1_42') # XXX
env.ParseConfig('pkg-config --cflags --libs gtkmm-2.4')
env.ParseConfig('pkg-config --cflags --libs giomm-2.4')
env.ParseConfig('pkg-config --cflags --libs exiv2')
env.Decider('timestamp-match')
env.Program('xmpedit', Glob('*.cpp'))
