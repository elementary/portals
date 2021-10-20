project('io.elementary.portals.demo', 'vala', 'c')

executable(
    meson.project_name(),
    'Application.vala',
    'MainWindow.vala',
    dependencies: [
        dependency('gtk+-3.0')
    ],
    install: true
)

install_data(
    'demo.desktop',
    install_dir: get_option('datadir') / 'applications',
    rename: meson.project_name() + '.desktop'
)