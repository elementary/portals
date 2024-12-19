/*
 * SPDX-FileCopyrigthText: 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Print")]
public class Print.Portal : Object {
    private DBusConnection connection;

    public Portal (DBusConnection connection) {
        this.connection = connection;
    }

    public async void print (
        ObjectPath handle,
        string app_id,
        string parent_window,
        string title,
        UnixInputStream fd,
        HashTable<string, Variant> options,
        out uint response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        // TODO Implement
    }

    public async void prepare_print (
        ObjectPath handle,
        string app_id,
        string parent_window,
        string title,
        HashTable<string, Variant> settings,
        HashTable<string, Variant> page_setup,
        HashTable<string, Variant> options,
        out uint response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        // TODO Implement
        var print_dialog = new Gtk.PrintUnixDialog (title, null) {
            print_settings = new Gtk.PrintSettings.from_gvariant (settings),
            page_setup = new Gtk.PageSetup.from_gvariant (page_setup)
        };

        var fake_window = new Gtk.Window ();
        print_dialog.set_transient_for (fake_window);

        var _results = new HashTable<string, Variant> (str_hash, str_equal);
        var _response = 2;

        print_dialog.response.connect ((id) => {
            switch (id) {
                case Gtk.ResponseType.OK:
                    _results["settings"] = print_dialog.print_settings.to_gvariant ();
                    _results["page-setup"] = print_dialog.page_setup.to_gvariant ();
                    // TODO Set random value
                    _results["token"] = 1;

                    _response = 0;
                    break;

                case Gtk.ResponseType.CANCEL:
                    _response = 1;
                    break;

                case Gtk.ResponseType.DELETE_EVENT:
                    _response = 2;
                    break;
            }

            prepare_print.callback ();
        });

        print_dialog.present ();
        yield;

        print_dialog.destroy ();

        results = _results;
        response = _response;
    }
}
