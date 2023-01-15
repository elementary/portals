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
        Dialog.ButtonAction action = Dialog.ButtonAction.SUGGESTED;
        string icon = "dialog-information";
        uint register_id = 0;

        if ("destructive" in options && options["destructive"].get_boolean ()) {
            action = Dialog.ButtonAction.DESTRUCTIVE;
        }

        if ("icon" in options) {
            // elementary HIG use non-symbolic icon, while portals ask for symbolic ones.
            icon = options["icon"].get_string ().replace ("-symbolic", "");
        }

        var dialog = new Dialog (action, app_id, parent_window, icon) {
            primary_text = title,
            secondary_text = sub_title,
            body = body
        };

        if ("modal" in options) {
            dialog.modal = options["modal"].get_boolean ();
        }

        if ("deny_label" in options) {
            dialog.deny_label = options["deny_label"].get_string ();
        }

        if ("grant_label" in options) {
            dialog.grant_label = options["grant_label"].get_string ();
        }

        if ("choices" in options) {
            var choices_iter = options["choices"].iterator ();
            Variant choice_variant;

            while ((choice_variant = choices_iter.next_value ()) != null) {
                dialog.add_choice (new Choice.from_variant (choice_variant));
            }
        }

        try {
            register_id = connection.register_object (handle, dialog);
        } catch (Error e) {
            critical (e.message);
        }

        var _results = new HashTable<string, Variant> (str_hash, str_equal);
        uint _response = 2;

        dialog.response.connect ((id) => {
            switch (id) {
                case Gtk.ResponseType.OK:
                    VariantBuilder choices_builder = new VariantBuilder (new VariantType ("a(ss)"));

                    dialog.get_choices ().foreach ((choice) => {
                        choices_builder.add ("(ss)", choice.name, choice.selected);
                    });

                    _results["choices"] = choices_builder.end ();
                    _response = 0;
                    break;
                case Gtk.ResponseType.CANCEL:
                    _response = 1;
                    break;
                case Gtk.ResponseType.DELETE_EVENT:
                    _response = 2;
                    break;
            }

            access_dialog.callback ();
        });

        dialog.present ();
        yield;

        connection.unregister_object (register_id);
        dialog.destroy ();

        results = _results;
        response = _response;
    }
}
