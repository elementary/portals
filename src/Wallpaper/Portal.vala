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
    public async void set_wallpaper_uri (
        ObjectPath handle,
        string app_id,
        string parent_window,
        string uri,
        HashTable<string, Variant> options,
        out uint32 response
    ) throws DBusError, IOError {
        var set_on = ""; // Possible values are background, lockscreen or both.
        var show_preview = false;

        if ("set-on" in options && options["set-on"].get_type_string () == "s") {
            set_on = options["show-preview"].get_string ();
        }

        if ("show-preview" in options && options["show-preview"].get_type_string () == "b") {
            show_preview = options["show-preview"].get_boolean ();
        }

        critical ("%b", show_preview);
        critical (set_on);

        // Lockscreen only isn't currently supported
        if (set_on == "locksreen") {
            response = 1;
            return;
        }

        var settings = new Settings ("org.gnome.desktop.background");
        settings.set_string ("picture-uri", uri);

        response = 0;
    }
}
