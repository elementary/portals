/*
 * Copyright 2019 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */
private static GLib.MainLoop loop;
public static GLib.HashTable<string, string> outstanding_handles;

private static bool opt_verbose = false;
private static bool opt_replace = false;
private static bool show_version = false;

private const GLib.OptionEntry[] OPTIONS_ENTRIES = {
    { "verbose", 'v', 0, OptionArg.NONE, ref opt_verbose, "Print debug information during command processing", null },
    { "replace", 'r', 0, OptionArg.NONE, ref opt_replace, "Replace a running instance", null },
    { "version", 0, 0, OptionArg.NONE, ref show_version, "Show program version", null },
    { null }
};

private void on_bus_acquired (DBusConnection connection, string name) {
    try {
        connection.register_object ("/org/freedesktop/portal/desktop", new Access.Portal (connection));
        debug ("Access Portal registered!");

        connection.register_object ("/org/freedesktop/portal/desktop", new AppChooser.Portal (connection));
        debug ("AppChooser Portal registered!");

        connection.register_object ("/org/freedesktop/portal/desktop", new Background.Portal (connection));
        debug ("Background Portal registered!");

        connection.register_object ("/org/freedesktop/portal/desktop", new Screenshot.Portal (connection));
        debug ("Screenshot Portal registered!");

        connection.register_object ("/org/freedesktop/portal/desktop", new Wallpaper.Portal (connection));
        debug ("Wallpaper Portal registered!");

        connection.register_object ("/org/freedesktop/portal/desktop", new ScreenCast.Portal (connection));
        debug ("Screencast Portal registered!");
    } catch (Error e) {
        critical ("Unable to register the object: %s", e.message);
    }
}

private void on_name_acquired () {
    debug ("org.freedesktop.impl.portal.desktop.pantheon acquired");

    // We're probably being started by xdg-desktop-portal, which won't be fully initialised until all the backends have loaded.
    // Granite depends on the settings portal to get the style preference, but can't DBus activate it because it's already starting.
    // The settings portal can't fully start because it's waiting on us, so break the cyclic nonsense by watching for xdg-desktop-portal
    // appearing before binding the style scheme
    uint watch_id = 0;
    watch_id = Bus.watch_name (BusType.SESSION, "org.freedesktop.portal.Desktop", BusNameWatcherFlags.NONE, () => {
        Granite.init ();

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        if (watch_id != 0) {
            Bus.unwatch_name (watch_id);
        }
    });

}

int main (string[] args) {
    GLib.Intl.setlocale (GLib.LocaleCategory.ALL, "");
    GLib.Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    GLib.Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
    GLib.Intl.textdomain (Config.GETTEXT_PACKAGE);

    /* Avoid pointless and confusing recursion */
    GLib.Environment.unset_variable ("GTK_USE_PORTAL");

    Gtk.init ();

    weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
    default_theme.add_resource_path ("/io/elementary/xdg-desktop-portal-pantheon");

    try {
        var opt_context = new OptionContext ("- portal backends");
        opt_context.set_summary ("A backend implementation for xdg-desktop-portal.");
        opt_context.set_description (
            "xdg-desktop-portal-pantheon provides D-Bus interfaces that\n"
            + "are used by xdg-desktop-portal to implement portals\n"
            + "\n"
            + "Documentation for the available D-Bus interfaces can be found at\n"
            + "https://flatpak.github.io/xdg-desktop-portal/portal-docs.html\n"
            + "\n"
            + "Please report issues at https://github.com/elementary/xdg-desktop-portal-pantheon/issues"
        );
        opt_context.add_main_entries (OPTIONS_ENTRIES, null);
        opt_context.parse (ref args);
    } catch (OptionError e) {
        printerr ("%s: %s\n", Environment.get_application_name (), e.message);
        printerr ("Try \"%s --help\" for more information.\n", Environment.get_prgname ());
        return 1;
    }

    if (show_version) {
        print ("%s \n", Config.VERSION);
        return 0;
    }

    if (opt_verbose) {
        GLib.Environment.set_variable ("G_MESSAGES_DEBUG", "all", false);
    }

    GLib.Environment.set_prgname ("xdg-desktop-portal-pantheon");
    loop = new GLib.MainLoop ();
    outstanding_handles = new GLib.HashTable<string, string> (str_hash, str_equal);

    GLib.DBusConnection session_bus;
    try {
        session_bus = GLib.Bus.get_sync (GLib.BusType.SESSION);
    } catch (Error e) {
        printerr ("No session bus: %s\n", e.message);
        return 2;
    }

    var owner_id = GLib.Bus.own_name (
        GLib.BusType.SESSION,
        "org.freedesktop.impl.portal.desktop.pantheon",
        GLib.BusNameOwnerFlags.ALLOW_REPLACEMENT | (opt_replace ? GLib.BusNameOwnerFlags.REPLACE : 0),
        on_bus_acquired,
        on_name_acquired,
        () => { loop.quit (); }
    );
    loop.run ();
    GLib.Bus.unown_name (owner_id);
    return 0;
}
