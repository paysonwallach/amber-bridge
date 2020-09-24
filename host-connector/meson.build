executable(
  '.'.join([meson.project_name(), 'host-connector']),
  files(
    'src/Main.vala'
  ),
  dependencies: [
    glib_dep,
    glib_json_dep,
    gio_dep,
    gio_unix_dep,
    posix_dep
  ],
  install: false
)
