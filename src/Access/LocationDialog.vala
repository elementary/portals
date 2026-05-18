/*
 * SPDX-FileCopyrightText: 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class Access.LocationDialog : Access.Dialog {
    public string app_id { get; construct; }

    public LocationDialog (string app_id) {
        Object (app_id: app_id);
    }

    construct {
        title = _("An application wants to access your location");
        secondary_text = _("Permissions can be changed in <a href='settings://security/privacy/location'>Location Settings…</a>");
        secondary_icon = new ThemedIcon ("emblem-portal-location");

        if (app_id != "") {
            var app_info = new DesktopAppInfo (app_id + ".desktop");
            if (app_info != null) {
                title = _("“%s” wants to access your location").printf (app_info.get_display_name ());
            }
        }
    }
}
