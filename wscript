APPNAME = 'xmpedit'
VERSION = '0.1'
top = '.'
out = 'target'

def set_options(opt):
    opt.tool_options('compiler_cxx')

def configure(conf):
    conf.check_tool('compiler_cxx')
    conf.check_cfg(package='gtkmm-2.4', args='--cflags --libs', mandatory=True)
    conf.check_cfg(package='giomm-2.4', args='--cflags --libs', mandatory=True)
    conf.check_cfg(package='exiv2', args='--cflags --libs', mandatory=True)

def build(bld):
    bld(
        features        = ['cxx', 'cprogram'],
        source          = bld.path.ant_glob('src/*.cpp'),
        target          = 'xmpedit',
        uselib          = ['GTKMM-2.4', 'GIOMM-2.4', 'EXIV2']
    )
