project(
  'com.paysonwallach.amber',
  'vala',
  'c',
  license: 'GPL-3.0',
  meson_version: '>=0.50.0',
  version: '0.1.0'
)

vala = meson.get_compiler('vala')

glib_dep = dependency('glib-2.0')
glib_json_dep = dependency('json-glib-1.0')
gio_dep = dependency('gio-2.0')
gio_unix_dep = dependency('gio-unix-2.0')
posix_dep = vala.find_library('posix')

subdir('host-connector')
subdir('opener')

meson.add_install_script('meson/post_install.py')
