install_data(
    'pantheon.portal',
    install_dir: join_paths(datadir, 'xdg-desktop-portal', 'portals')
)

configure_file(
    input: 'org.freedesktop.impl.portal.desktop.pantheon.service.in',
    output: '@BASENAME@',
    configuration: conf_data,
    install: true,
    install_dir: join_paths(datadir, 'dbus-1', 'services')
)

systemd_systemduserunitdir = get_option('systemduserunitdir')
if systemd_systemduserunitdir == ''
    systemd_systemduserunitdir = systemd_dep.get_pkgconfig_variable('systemduserunitdir', define_variable: ['prefix', prefix])
endif

configure_file(
    input: meson.project_name() + '.service.in',
    output: '@BASENAME@',
    configuration: conf_data,
    install: true,
    install_dir: systemd_systemduserunitdir
)
