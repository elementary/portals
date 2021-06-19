/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class AppChooser.AppButton : Gtk.Button {
    public string app_id { get; construct; }

    public AppButton (string app_id) {
        Object (app_id: app_id);
    }

    construct {
        var info = new DesktopAppInfo (app_id + ".desktop");

        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var icon = new Gtk.Image () {
            gicon = info.get_icon () ?? new ThemedIcon ("x-application-default"),
            icon_size = Gtk.IconSize.DIALOG
        };

        var name = new Gtk.Label (info.get_display_name ()) {
            ellipsize = Pango.EllipsizeMode.END,
            justify = Gtk.Justification.CENTER,
            lines = 2,
            max_width_chars = 10,
            width_chars = 10,
            wrap_mode = Pango.WrapMode.WORD_CHAR
        };

        var grid = new Gtk.Grid () {
            halign = Gtk.Align.CENTER,
            margin = 6,
            row_spacing = 6
        };
        grid.attach (icon, 0, 0);
        grid.attach (name, 0, 1);

        add (grid);
    }
}
