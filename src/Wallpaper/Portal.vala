/*
 * SPDX-FileCopyrigthText: 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Wallpaper")]
public class Wallpaper.Portal : Object {
    private DBusConnection connection;

    public Portal (DBusConnection connection) {
        this.connection = connection;
    }

    [DBus (name = "SetWallpaperURI")]
    public async uint set_wallpaper_uri (
        ObjectPath handle,
        string app_id,
        string parent_window,
        string uri,
        HashTable<string, Variant> options
    ) throws DBusError, IOError {
        var set_on = "both"; // Possible values are background, lockscreen or both.
        var show_preview = false;

        unowned var _set_on = options.get ("set-on");
        if (_set_on.get_type_string () == "s") {
            set_on = _set_on.get_string ();
        }

        unowned var _show_preview = options.get ("show-preview");
        if (_show_preview.get_type_string () == "b") {
            show_preview = _show_preview.get_boolean ();
        }

        // Currently only support Both
        if (set_on == "background" || set_on == "lockscreen") {
            return 1;
        }

        var file = File.new_for_uri (uri);
        if (!get_is_file_in_bg_dir (file)) {
            file = copy_for_library (file);
        }

        if (file != null) {
            var settings = new Settings ("org.gnome.desktop.background");
            settings.set_string ("picture-uri", file.get_uri ());
        }

        return 0;
    }

    private bool get_is_file_in_bg_dir (File file) {
        string path = file.get_path ();

        foreach (unowned string directory in get_bg_directories ()) {
            if (path.has_prefix (directory)) {
                return true;
            }
        }

        return false;
    }

    private File? copy_for_library (File source) {
        File? dest = null;

        try {
            var timestamp = new DateTime.now_local ().format ("%Y-%m-%d-%H-%M-%S");
            var filename = "%s-%s".printf (timestamp, source.get_basename ());
            dest = ensure_local_bg_exists ().get_child (filename);
            source.copy (dest, FileCopyFlags.OVERWRITE | FileCopyFlags.ALL_METADATA);
        } catch (Error e) {
            warning (e.message);
        }

        return dest;
    }

    private string[] get_bg_directories () {
        string[] background_directories = {};

        // Add user background directory first
        background_directories += get_local_bg_directory ();

        foreach (var bg_dir in get_system_bg_directories ()) {
            background_directories += bg_dir;
        }

        if (background_directories.length == 0) {
            warning ("No background directories found");
        }

        return background_directories;
    }

    private File ensure_local_bg_exists () {
        var folder = File.new_for_path (get_local_bg_directory ());
        if (!folder.query_exists ()) {
            try {
                folder.make_directory_with_parents ();
            } catch (Error e) {
                warning (e.message);
            }
        }

        return folder;
    }

    private string get_local_bg_directory () {
        return Path.build_filename (Environment.get_user_data_dir (), "backgrounds") + "/";
    }

    private string[] get_system_bg_directories () {
        string[] directories = {};
        foreach (unowned string data_dir in Environment.get_system_data_dirs ()) {
            var system_background_dir = Path.build_filename (data_dir, "backgrounds") + "/";
            if (FileUtils.test (system_background_dir, FileTest.EXISTS)) {
                debug ("Found system background directory: %s", system_background_dir);
                directories += system_background_dir;
            }
        }

        return directories;
    }
}
