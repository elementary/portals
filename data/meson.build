install_data(
    'pantheon.portal',
    install_dir: join_paths(datadir, 'xdg-desktop-portal', 'portals')
)

systemd_systemduserunitdir = get_option('systemduserunitdir')
if systemd_systemduserunitdir == ''
    systemd_dep.get_pkgconfig_variable('systemduserunitdir', define_variable: ['prefix', prefix])
endif

configure_file(
    input: meson.project_name() + '.service.in',
    output: meson.project_name() + '.service',
    configuration: conf_data,
    install_dir: systemd_systemduserunitdir,
)
