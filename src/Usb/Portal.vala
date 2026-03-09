/*
 * SPDX-FileCopyrigthText: 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Usb")]
public class Usb.Portal : Object {
    private DBusConnection connection;

    public Portal (DBusConnection connection) {
        this.connection = connection;
    }

    [DBus (name = "AcquireDevices")]
    public async void acquire_devices (
        ObjectPath handle,
        string parent_window,
        string app_id,
        // G_VARIANT_BUILDER_INIT (G_VARIANT_TYPE ("a(sa{sv})"));
      // IN devices a(sa{sv}a{sv}),
        HashTable<string, Variant> options,
        out uint response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        var dialog = new Dialog (app_id) {
            parent_handle = parent_window
        };

        if ("reason" in options) {
            dialog.reason = options["reason"].get_string ();
        }

        try {
            dialog.register_id = connection.register_object<Dialog> (handle, dialog);
        } catch (Error e) {
            critical (e.message);
        }

        var _results = new HashTable<string, Variant> (str_hash, str_equal);
        uint _response = 2;

        dialog.response.connect ((response) => {
            switch (response) {
                case ALLOW:

                    break;
                default:
                    break;
            }

            _response = response.to_id ();

            acquire_devices.callback ();
        });

        dialog.present ();
        yield;

        connection.unregister_object (dialog.register_id);
        dialog.destroy ();

        results = _results;
        response = _response;
    }
}
