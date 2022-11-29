conf_file = configure_file(
    input: 'Config.vala.in',
    output: '@BASENAME@',
    configuration: conf_data
)

executable(
    meson.project_name(),
    conf_file,
    'XdgDesktopPortalPantheon.vala',
    'ExternalWindow.vala',
    'Access/Portal.vala',
    'Access/Dialog.vala',
    'Access/Choice.vala',
    'AppChooser/Portal.vala',
    'AppChooser/Dialog.vala',
    'AppChooser/AppButton.vala',
    'Share/Dialog.vala',
    'Share/Portal.vala',
    dependencies: [
        glib_dep,
        gobject_dep,
        gio_dep,
        gtk_dep,
        gdk_dep,
        x11_dep,
        granite_dep,
        handy_dep
    ],
    install: true,
    install_dir: libexecdir,
)
