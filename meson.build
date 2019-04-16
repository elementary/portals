project('xdg-desktop-portal-pantheon', 'c', 'vala')

systemd_dep = dependency('systemd')

glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gio_dep = dependency('gio-2.0')
gtk_dep = dependency('gtk+-3.0')

conf_data = configuration_data()
conf_data.set('LIBEXECDIR', join_paths(get_option('prefix'), get_option('libexecdir')))

subdir('data')
subdir('src')
