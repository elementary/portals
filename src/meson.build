executable(
    meson.project_name(),
    'XdgDesktopPortalPantheon.vala',
    'filechooser-portal/FileChooser.vala',
    'filechooser-portal/FileChooserDialog.vala',
    dependencies: [
        glib_dep,
        gobject_dep,
        gio_dep,
        gtk_dep,
        granite_dep,
        pantheon_files_lib_dep,
        pantheon_file_core_c_dep,
        pantheon_files_widgets_lib_dep,
        pantheon_files_core_lib_dep,
        posix_dep,
        unity_dep
    ],
    install: true,
    install_dir: get_option('libexecdir'),
)
