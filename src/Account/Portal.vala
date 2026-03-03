/*
 * SPDX-FileCopyrigthText: 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Account")]
public class Account.Portal : Object {
    private HashTable<ObjectPath, Dialog> handles;
    private DBusConnection connection;

    public Portal (DBusConnection connection) {
        this.connection = connection;
    }

    [DBus (name = "GetUserInformation")]
    public async void get_user_information (
        ObjectPath handle,
        string app_id,
        string parent_window,
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

        dialog.response.connect ((id) => {
            switch (id) {
                case ALLOW:
                    _results["id"] = dialog.user_name;
                    _results["name"] = dialog.real_name;
                    _results["image"] = dialog.image_uri;

                    _response = 0;
                    break;

                case CANCEL:
                    _response = 1;
                    break;
            }

            get_user_information.callback ();
        });

        handles[handle] = dialog;
        dialog.present ();
        yield;

        connection.unregister_object (dialog.register_id);
        dialog.destroy ();

        results = _results;
        response = _response;
    }
}
