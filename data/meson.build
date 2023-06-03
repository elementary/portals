install_data(
    'pantheon.portal',
    install_dir: datadir / 'xdg-desktop-portal' / 'portals'
)

configure_file(
    input: 'org.freedesktop.impl.portal.desktop.pantheon.service.in',
    output: '@BASENAME@',
    configuration: conf_data,
    install: true,
    install_dir: datadir / 'dbus-1' / 'services'
)

systemduserunitdir = get_option('systemduserunitdir')
if systemduserunitdir == ''
    systemduserunitdir = systemd_dep.get_variable('systemduserunitdir', pkgconfig_define: [ 'prefix', prefix ])
endif

configure_file(
    input: meson.project_name() + '.service.in',
    output: '@BASENAME@',
    configuration: conf_data,
    install: true,
    install_dir: systemduserunitdir
)

i18n.merge_file(
    input: 'portals.metainfo.xml.in',
    output: 'io.elementary.portals.metainfo.xml',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    type: 'xml',
    install: true,
    install_dir: datadir / 'metainfo'
)
