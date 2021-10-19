/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

 public class AccountChooser.AccountButton : Gtk.Button {
    public string account_id { get; construct; }

    public AccountButton (string account_id) {
        Object (account_id: account_id);
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var name = new Gtk.Label (account_id) {
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
        grid.add (name);

        add (grid);
    }
}
