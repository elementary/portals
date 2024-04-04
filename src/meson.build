executable(
    meson.project_name(),
    'Access/Choice.vala',
    'Access/Dialog.vala',
    'Access/Portal.vala',
    'AppChooser/AppButton.vala',
    'AppChooser/Dialog.vala',
    'AppChooser/Portal.vala',
    'Background/NotificationRequest.vala',
    'Background/Portal.vala',
    'ScreenCast/Portal.vala',
    'ScreenCast/Session.vala',
    'Wallpaper/Portal.vala',
    configure_file(input: 'Config.vala.in', output: '@BASENAME@', configuration: conf_data),
    'ExternalWindow.vala',
    'XdgDesktopPortalPantheon.vala',
    dependencies: [
        glib_dep,
        gobject_dep,
        gio_dep,
        granite_dep,
        gtk_deps,
        x11_dep
    ],
    install: true,
    install_dir: libexecdir
)
