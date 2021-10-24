/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class AppChooser.AppButton : Gtk.ListBoxRow {
    public string app_id { get; construct; }

    public AppButton (string app_id) {
        Object (app_id: app_id);
    }

    construct {
        var app_info = new DesktopAppInfo (app_id + ".desktop");

        var icon = new Gtk.Image () {
            gicon = app_info.get_icon () ?? new ThemedIcon ("application-default-icon"),
            icon_size = Gtk.IconSize.DND
        };

        var name = new Gtk.Label (app_info.get_display_name ()) {
            ellipsize = Pango.EllipsizeMode.END
        };

        var grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 3,
            margin_start = 6,
            margin_end = 6
        };
        grid.add (icon);
        grid.add (name);

        add (grid);
    }
}
