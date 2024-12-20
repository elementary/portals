/*
 * SPDX-FileCopyrigthText: 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class Print.Dialog : Gtk.Window {
    // The ID used to register this dialog on the DBusConnection
    public uint register_id { get; set; default = 0; }

    public Dialog (
    ) {
        Object (
        );
    }

    construct {
    }
}
