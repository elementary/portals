project('io.elementary.portals.demo', 'vala', 'c')

install_data(
    'demo.desktop',
    install_dir: get_option('datadir') / 'applications',
    rename: meson.project_name() + '.desktop'
)

gnome = import('gnome')
resources = gnome.compile_resources(
    'demo-resources', 'data/demo.gresource.xml',
    source_dir: 'data',
    c_name: 'demo'
)

executable(
    meson.project_name(),
    'Application.vala',
    'MainWindow.vala',
    'Views' / 'AppChooser.vala',
    resources,
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite', version: '>= 6.0.0')
    ],
    install: true
)