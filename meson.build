project('xdg-desktop-portal-pantheon', 'c', 'vala', version: '8.0.0', meson_version: '>=0.58')

gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = prefix / get_option('datadir')
libexecdir = prefix / get_option('libexecdir')
localedir = prefix / get_option('localedir')

systemd_dep = dependency('systemd')

glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gio_dep = dependency('gio-2.0')
granite_dep = dependency('granite-7')

gtk_deps = [
    dependency('gtk4'),
    dependency('gtk4-unix-print')
]

if meson.get_compiler('vala').version().version_compare('>=0.56.1')
    gtk_deps += [
        dependency('gtk4-x11'),
        dependency('gtk4-wayland')
    ]
endif

pantheon_wayland_dep = dependency('pantheon-wayland-1')
x11_dep = dependency('x11')

add_project_arguments(
    '--vapidir', meson.current_source_dir() / 'vapi',
    language: 'vala'
)

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()),
    language: 'c'
)

conf_data = configuration_data()
conf_data.set('LIBEXECDIR', libexecdir)
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('LOCALEDIR', localedir)
conf_data.set_quoted('VERSION', meson.project_version())

subdir('data')
subdir('po')
subdir('src')
