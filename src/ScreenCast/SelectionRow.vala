/*
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 *
 * Authored by: Leonhard Kargl <leo.kargl@proton.me>
 */

public class ScreenCast.SelectionRow : Gtk.ListBoxRow {
    public SourceType source_type { get; construct; }
    public Variant id { get; construct; }
    public string label { get; construct; }
    public Icon icon { get; construct; }
    public Gtk.CheckButton? group { get; construct; }

    public Gtk.CheckButton check_button { get; construct; }

    public bool selected { get; set; default = false; }

    public string description {
        set {
            var description_label = new Gtk.Label (value) {
                ellipsize = MIDDLE,
                hexpand = true,
                lines = 2,
                wrap = true,
                xalign = 0
            };
            description_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
            description_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

            label_box.append (description_label);
        }
    }

    private Gtk.Box label_box;

    public SelectionRow (SourceType source_type, Variant id, string label, Icon icon, Gtk.CheckButton? group) {
        Object (
            source_type: source_type,
            id: id,
            label: label,
            icon: icon,
            group: group
        );
    }

    construct {
        check_button = new Gtk.CheckButton () {
            group = group
        };

        var image = new Gtk.Image.from_gicon (icon) {
            icon_size = LARGE
        };

        var title_label = new Gtk.Label (label) {
            ellipsize = MIDDLE,
            xalign = 0
        };

        label_box = new Gtk.Box (VERTICAL, 0) {
            margin_start = 6,
            valign = CENTER
        };
        label_box.append (title_label);

        var box = new Gtk.Box (HORIZONTAL, 0);
        box.append (check_button);
        box.append (image);
        box.append (label_box);

        child = box;

        check_button.bind_property ("active", this, "selected", DEFAULT);
    }
}
