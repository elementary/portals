/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Share")]
public class Share.Portal : Object {
    private HashTable<ObjectPath, Dialog> handles;
    private DBusConnection connection;

    public Portal (DBusConnection connection) {
        handles = new HashTable<ObjectPath, Dialog> (str_hash, str_equal);
        this.connection = connection;
    }

    public async void share (
        ObjectPath handle,
        string app_id,
        string parent_window,
        HashTable<string, Variant> options
    ) throws DBusError, IOError {
        string content_type = "";
        string filename = "";

        if ("content_type" in options && options["content_type"].is_of_type (VariantType.STRING)) {
            content_type = options["content_type"].get_string ();
        }

        if ("filename" in options && options["filename"].is_of_type (VariantType.STRING)) {
            filename = options["filename"].get_string ();
        }

        var dialog = new AppChooser.Dialog (
            app_id,
            parent_window,
            content_type,
            filename
        );

        if ("modal" in options && options["modal"].is_of_type (VariantType.BOOLEAN)) {
            dialog.modal = options["modal"].get_boolean ();
        }

        try {
            dialog.register_id = connection.register_object<Dialog> (handle, dialog);
        } catch (Error e) {
            critical (e.message);
        }


        var _results = new HashTable<string, Variant> (str_hash, str_equal);
        uint _response = 2;

        dialog.destroy.connect (() => {
            if (dialog.register_id != 0) {
                connection.unregister_object (dialog.register_id);
            }
        });

        handles[handle] = dialog;
        dialog.show_all ();
    }
}
