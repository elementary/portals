/*
 * SPDX-FileCopyrigthText: 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class Account.Dialog : PortalDialog {
    // The ID used to register this dialog on the DBusConnection
    public uint register_id { get; set; default = 0; }

    // The ID of the app sending the request
    public string app_id { get; construct; }

    public Dialog (string app_id) {
        Object (app_id: app_id);
    }

    construct {
        default_height = -1;
        title = _("An application wants to access your personal information");
        secondary_icon = new ThemedIcon ("system-users");

        if (app_id != "") {
            var app_info = new DesktopAppInfo (app_id + ".desktop");
            if (app_info != null) {
                primary_icon = app_info.get_icon ();
                title = _("“%s” wants to access your personal information").printf (app_info.get_display_name ());
            }
        }
    }
}
