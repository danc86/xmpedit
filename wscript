APPNAME = 'xmpedit'
VERSION = '0.1'
top = '.'
out = 'target'

def options(opt):
    opt.tool_options('compiler_cc')
    opt.tool_options('vala')

def configure(conf):
    conf.check_tool('compiler_cc vala')
    conf.check_cfg(package='gtk+-2.0', atleast_version='2.18.0', args='--cflags --libs', mandatory=True)
    conf.check_cfg(package='gee-1.0', args='--cflags --libs', mandatory=True)
    conf.check_cfg(package='gexiv2', args='--cflags --libs', mandatory=True)
    conf.env.append_unique('VALAFLAGS', ['-g'])

def build(bld):
    bld.add_subdirs('src')
