/*
 * SPDX-FileCopyrigthText: 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Account")]
public class Account.Portal : Object {
    private DBusConnection connection;

    public Portal (DBusConnection connection) {
        this.connection = connection;
    }

    [DBus (name = "GetUserInformation")]
    public void get_user_information (
        ObjectPath handle,
        string app_id,
        string parent_window,
        HashTable<string, Variant> options,
        out uint32 response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        var dialog = new PortalDialog () {
            title = _("An application wants to access your personal information"),
            secondary_icon = new ThemedIcon ("preferences-desktop-useraccounts"),
            secondary_text = _("It did not provide a reason for this request."),
            parent_handle = parent_window
        };

        if (app_id != "") {
            var app_info = new DesktopAppInfo (app_id + ".desktop");
            if (app_info != null) {
                dialog.primary_icon = app_info.get_icon ();
                dialog.title = _("“%s” wants to access your personal information").printf (app_info.get_display_name ());
            }
        }

        if ("reason" in options) {
            ("It provided the following reason, “%s”").printf (options["reason"].get_string ());
        }

        var _results = new HashTable<string, Variant> (str_hash, str_equal);
        var _response = 2;

        dialog.response.connect ((id) => {
            switch (id) {
                case ALLOW:
                    _response = 0;
                    break;

                case CANCEL:
                    _response = 1;
                    break;
            }

            dialog.destroy ();
        });

        dialog.present ();
    }
}
