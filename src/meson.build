executable(
    meson.project_name(),
    'Access/Choice.vala',
    'Access/Dialog.vala',
    'Access/Portal.vala',
    'AppChooser/AppButton.vala',
    'AppChooser/Dialog.vala',
    'AppChooser/Portal.vala',
    configure_file(input: 'Config.vala.in', output: '@BASENAME@', configuration: conf_data),
    'ExternalWindow.vala',
    'XdgDesktopPortalPantheon.vala',
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
    install_dir: libexecdir
)
