/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class Screenshot.Dialog : Gtk.Window {
    public string parent_window { get; construct; }
    public bool permission_store_checked { get; construct; }
    
    public Dialog (string parent_window, bool modal, bool permission_store_checked) {
        Object (
            resizable: false,
            parent_window: parent_window,
            modal: modal,
            permission_store_checked: permission_store_checked
        );
    }

    private Gtk.Image all_image;

    construct {
        all_image = new Gtk.Image.from_icon_name ("grab-screen-symbolic");

        var all = new Gtk.CheckButton () {
            active = true,
            tooltip_text = _("Grab the whole screen")
        };
        all.add_css_class ("image-button");
        all_image.set_parent (all);

        var curr_image = new Gtk.Image.from_icon_name ("grab-window-symbolic");

        var curr_window = new Gtk.CheckButton () {
            group = all,
            tooltip_text = _("Grab the current window")
        };
        curr_window.add_css_class ("image-button");
        curr_image.set_parent (curr_window);

        var selection_image = new Gtk.Image.from_icon_name ("grab-area-symbolic");

        var selection = new Gtk.CheckButton () {
            group = all,
            tooltip_text = _("Select area to grab")
        };
        selection.add_css_class ("image-button");
        selection_image.set_parent (selection);

        var pointer_label = new Gtk.Label (_("Grab pointer:")) {
            halign = END
        };

        var pointer_switch = new Gtk.Switch () {
            halign = START
        };

        var close_label = new Gtk.Label (_("Close after saving:")) {
            halign = END
        };

        var close_switch = new Gtk.Switch () {
            halign = START
        };

        var redact_label = new Gtk.Label (_("Conceal text:")) {
            halign = END
        };

        var redact_switch = new Gtk.Switch () {
            halign = START
        };

        var delay_label = new Gtk.Label (_("Delay in seconds:"));
        delay_label.halign = Gtk.Align.END;

        var delay_spin = new Gtk.SpinButton.with_range (0, 15, 1);

        var take_btn = new Gtk.Button.with_label (_("Take Screenshot")) {
            receives_default = true
        };
        take_btn.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var close_btn = new Gtk.Button.with_label (_("Close"));

        var radio_box = new Gtk.Box (HORIZONTAL, 18) {
            halign = CENTER
        };
        radio_box.append (all);
        radio_box.append (curr_window);
        radio_box.append (selection);

        var option_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6
        };
        option_grid.attach (pointer_label, 0, 0);
        option_grid.attach (pointer_switch, 1, 0);
        option_grid.attach (close_label, 0, 1);
        option_grid.attach (close_switch, 1, 1);

        option_grid.attach (redact_label, 0, 2);
        option_grid.attach (redact_switch, 1, 2);

        option_grid.attach (delay_label, 0, 3);
        option_grid.attach (delay_spin, 1, 3);

        var actions = new Gtk.Box (HORIZONTAL, 6) {
            halign = END,
            homogeneous = true
        };
        actions.append (close_btn);
        actions.append (take_btn);

        var box = new Gtk.Box (VERTICAL, 24) {
            margin_top = 24,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };
        box.append (radio_box);
        box.append (option_grid);
        box.append (actions);

        child = box;

        close_btn.clicked.connect (() => {
            destroy ();
        });

        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.notify["gtk-application-prefer-dark-theme"].connect (() => {
            update_icons (gtk_settings.gtk_application_prefer_dark_theme);
        });

        update_icons (gtk_settings.gtk_application_prefer_dark_theme);
    }

    private void update_icons (bool prefers_dark) {
        if (prefers_dark) {
            all_image.icon_name = "grab-screen-symbolic-dark";
        } else {
            all_image.icon_name = "grab-screen-symbolic";
        }
    }
}