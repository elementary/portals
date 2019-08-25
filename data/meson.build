install_data(
    'pantheon.portal',
    install_dir: join_paths(datadir, 'xdg-desktop-portal', 'portals')
)

configure_file(
    input: meson.project_name() + '.service.in',
    output: meson.project_name() + '.service',
    configuration: conf_data,
    install_dir: systemd_dep.get_pkgconfig_variable('systemduserunitdir')
)
