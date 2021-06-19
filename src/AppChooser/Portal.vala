/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.AppChooser")]
public class AppChooser.Portal : Object {
    private HashTable<ObjectPath, Dialog> handles;
    private DBusConnection connection;

    public Portal (DBusConnection connection) {
        handles = new HashTable<ObjectPath, Dialog> (str_hash, str_equal);
        this.connection = connection;
    }

    public async void choose_application (
        ObjectPath handle,
        string app_id,
        string parent_window,
        string[] choices,
        HashTable<string, Variant> options,
        out uint response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        var dialog = new Dialog (connection, handle, app_id, parent_window);

        if ("last_choice" in options && options["last_choice"].is_of_type (VariantType.STRING)) {
            dialog.last_choice = options["last_choice"].get_string ();
        } if ("modal" in options && options["modal"].is_of_type (VariantType.BOOLEAN)) {
            dialog.modal = options["modal"].get_boolean ();
        } if ("content_type" in options && options["content_type"].is_of_type (VariantType.STRING)) {
            dialog.content_type = options["content_type"].get_string ();
        } if ("filename" in options && options["filename"].is_of_type (VariantType.STRING)) {
            dialog.filename = options["filename"].get_string ();
        }

        dialog.update_choices (choices);
        var _results = new HashTable<string, Variant> (str_hash, str_equal);
        uint _response = 2;

        var destroy_id = dialog.destroy.connect_after (() => {
            _results["choice"] = "";
            choose_application.callback ();
        });

        dialog.chosen.connect ((app_id) => {
            dialog.disconnect (destroy_id);

            _results["choice"] = app_id.replace (".desktop", "");
            _response = app_id == "" ? 1 : 0;

            choose_application.callback ();
        });

        handles[handle] = dialog;
        dialog.show_all ();
        yield;

        results = _results;
        response = _response;
    }

    public async void update_choices (ObjectPath handle, string[] choices) throws DBusError, IOError {
        if (handle in handles) {
            handles[handle].update_choices (choices);
        }
    }
}
