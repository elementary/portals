/*
 * SPDX-FileCopyrightText: 2021-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Access")]
public class Access.Portal : Object {
    private DBusConnection connection;

    public Portal (DBusConnection connection) {
        this.connection = connection;
    }

    public async void access_dialog (
        ObjectPath handle,
        string app_id,
        string parent_window,
        string title,
        string sub_title,
        string body,
        HashTable<string, Variant> options,
        out uint32 response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        uint register_id = 0;

        var dialog = new Dialog () {
            title = title,
            secondary_text = sub_title,
            body = body,
            parent_handle = parent_window
        };

        if (app_id != "") {
            dialog.primary_icon = new DesktopAppInfo (app_id + ".desktop").get_icon ();
        } else {
            // non-sandboxed access must be the system itself
            dialog.primary_icon = new ThemedIcon ("io.elementary.settings");
        }

        if ("destructive" in options && options["destructive"].get_boolean ()) {
            dialog.action_type = DESTRUCTIVE;
        }

        if ("icon" in options) {
            // elementary HIG use non-symbolic icon, while portals ask for symbolic ones.
             dialog.secondary_icon = new ThemedIcon (options["icon"].get_string ().replace ("-symbolic", ""));
        }

        if ("modal" in options) {
            dialog.modal = options["modal"].get_boolean ();
        }

        if ("deny_label" in options) {
            dialog.cancel_label = options["deny_label"].get_string ();
        }

        if ("grant_label" in options) {
            dialog.allow_label = options["grant_label"].get_string ();
        }

        if ("choices" in options) {
            var choices_iter = options["choices"].iterator ();
            Variant choice_variant;

            while ((choice_variant = choices_iter.next_value ()) != null) {
                dialog.add_choice (new Choice.from_variant (choice_variant));
            }
        }

        var _results = new HashTable<string, Variant> (str_hash, str_equal);
        var _response = 2;

        dialog.response.connect ((id) => {
            switch (id) {
                case ALLOW:
                    var choices_builder = new VariantBuilder (new VariantType ("a(ss)"));

                    dialog.get_choices ().foreach ((choice) => {
                        choices_builder.add ("(ss)", choice.name, choice.selected);
                    });

                    _results["choices"] = choices_builder.end ();
                    _response = 0;
                    break;

                case CANCEL:
                    _response = 1;
                    break;

                case DELETE_EVENT:
                    _response = 2;
                    break;
            }

            access_dialog.callback ();
        });

        try {
            register_id = connection.register_object (handle, dialog);
        } catch (IOError e) {
            warning (e.message);
            throw new DBusError.OBJECT_PATH_IN_USE (e.message);
        }

        dialog.present ();
        yield;

        connection.unregister_object (register_id);
        dialog.destroy ();

        results = _results;
        response = _response;
    }
}
