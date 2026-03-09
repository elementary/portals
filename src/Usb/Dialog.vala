/*
 * SPDX-FileCopyrigthText: 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class Usb.Dialog : PortalDialog {
    // The ID used to register this dialog on the DBusConnection
    public uint register_id { get; set; default = 0; }

    // The ID of the app sending the request
    public string app_id { get; construct; }

    public string reason {
        set {
            secondary_text = _("It provided the following reason, “%s”").printf (value);
        }
    }

    public Dialog (string app_id) {
        Object (app_id: app_id);
    }

    construct {
        default_height = -1;
        title = _("An application wants to access the following USB devices");
        secondary_icon = new ThemedIcon ("emblem-portal-usb");
        secondary_text = _("It did not provide a reason for this request.");

        if (app_id != "") {
            var app_info = new DesktopAppInfo (app_id + ".desktop");
            if (app_info != null) {
                primary_icon = app_info.get_icon ();
                title = _("“%s” wants to access the following USB devices").printf (app_info.get_display_name ());
            }
        }

    }

    [DBus (name = "Close")]
    public void on_close () throws DBusError, IOError {
        response (DELETE_EVENT);
    }
}
