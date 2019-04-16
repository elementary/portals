project('xdg-desktop-portal-pantheon', 'c', 'vala')

add_project_arguments(
    ['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
    language: 'vala'
)

systemd_dep = dependency('systemd')
vala = meson.get_compiler('vala')

glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gio_dep = dependency('gio-2.0')
gtk_dep = dependency('gtk+-3.0')


posix_dep = vala.find_library('posix')
unity_dep = dependency('unity')

pantheon_file_core_c_dep = vala.find_library('pantheon-files-core-C', dirs: join_paths(meson.current_source_dir(), 'vapi'))
pantheon_files_lib_dep = dependency('pantheon-files')
pantheon_files_core_lib_dep = dependency('pantheon-files-core')
pantheon_files_widgets_lib_dep = dependency('pantheon-files-widgets')
granite_dep = dependency('granite')

conf_data = configuration_data()
conf_data.set('LIBEXECDIR', join_paths(get_option('prefix'), get_option('libexecdir')))

subdir('data')
subdir('src')
