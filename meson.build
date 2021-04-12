project(
  'com.paysonwallach.amber.bridge',
  'vala',
  'c',
  license: 'GPL-3.0',
  meson_version: '>=0.55.0',
  version: '0.1.0'
)

cmake = import('cmake')
vala = meson.get_compiler('vala')

vapi_dir = join_paths(meson.current_source_dir(), 'vapi')

add_project_arguments(
  ['-DG_LOG_DOMAIN="com.paysonwallach.amber.bridge"'],
  language:'c'
)

add_project_arguments(
  ['--vapidir', vapi_dir],
  language: 'vala'
)

nfd_opts = cmake.subproject_options()

if get_option('buildtype') == 'release'
  nfd_opts.add_cmake_defines({'CMAKE_BUILD_TYPE': 'Release'})
endif

nfd = cmake.subproject('nativefiledialog-extended', options: nfd_opts)
nfd_dep = nfd.dependency('nfd')

gee_dep = dependency('gee-0.8')
glib_dep = dependency('glib-2.0')
glib_json_dep = dependency('json-glib-1.0')
gio_dep = dependency('gio-2.0')
gio_unix_dep = dependency('gio-unix-2.0')
gtk_dep = dependency('gtk+-3.0')
posix_dep = vala.find_library('posix')

conf = configuration_data()
conf.set_quoted('APP_ID', meson.project_name())
conf.set_quoted('API_VERSION', 'v1')

config_h = configure_file(
  output: 'config.h',
  configuration: conf
)

config_inc_dir = include_directories('.')

config_dep = declare_dependency(
  dependencies: vala.find_library('config', dirs: vapi_dir),
  sources: config_h
)

bridge_source_files = [
  'src/ExtensionProxy.vala',
  'src/Main.vala',
  'src/Protocol.vala',
  'src/Utils/Filename.vala',
  'src/Utils/Serializable.vala'
]

dependencies = [
  gee_dep,
  glib_dep,
  glib_json_dep,
  gio_dep,
  gio_unix_dep,
  gtk_dep,
  posix_dep,
  nfd_dep,
  vala.find_library('nfd', dirs: vapi_dir),
  config_dep
]

if get_option('gtk3').enabled()
  dependencies += dependency('gtk+-3.0')
endif

executable(
  meson.project_name(),
  bridge_source_files,
  include_directories: config_inc_dir,
  dependencies: dependencies,
  install: true
)

meson.add_install_script(
  'meson/post_install.py',
  get_option('browsers')
)
