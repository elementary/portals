/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class AppChooser.AppButton : Gtk.Button {
    public AppInfo info { get; construct; }

    public AppButton (string app_id) {
        Object (info: new DesktopAppInfo (app_id + ".desktop"));
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var icon = new Gtk.Image () {
            gicon = info.get_icon () ?? new ThemedIcon ("x-application-default"),
            icon_size = Gtk.IconSize.DIALOG,
            margin_top = 9,
            margin_end = 6,
            margin_start = 6
        };

        var name = new Gtk.Label (info.get_display_name ()) {
            halign = Gtk.Align.CENTER,
            justify = Gtk.Justification.CENTER,
            lines = 2,
            max_width_chars = 16,
            width_chars = 16,
            wrap_mode = Pango.WrapMode.WORD_CHAR
        };
        name.set_ellipsize (Pango.EllipsizeMode.END);

        var grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            halign = Gtk.Align.CENTER
        };
        grid.add (icon);
        grid.add (name);

        add (grid);
    }
}
