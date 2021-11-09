/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class Share.Dialog : Hdy.Window {
    // The ID used to register this dialog on the DBusConnection
    public uint register_id { get; set; default = 0; }

    // The ID of the app sending the request
    public string app_id { get; construct; }

    public string parent_window { get; construct; }

    // The content type to choose an application for
    public string content_type { get; construct ; }

    // The filename to choose an app for. That this is just a basename, without a path
    public string filename { get; construct; }


    public Dialog (
        string app_id,
        string parent_window,
        string content_type,
        string filename
    ) {
        Object (
            app_id: app_id,
            parent_window: parent_window,
            content_type: content_type,
            filename: filename
        );
    }

    construct {

    }

    [DBus (name = "Close")]
    public void on_close () throws DBusError, IOError {
        destroy ();
    }
}
