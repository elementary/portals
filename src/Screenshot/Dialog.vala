/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class Screenshot.Dialog : Gtk.Window {
    public enum ScreenshotType {
        ALL,
        WINDOW,
        AREA
    }

    public signal void response (Gtk.ResponseType response_type);

    public string parent_window { get; construct; }
    public bool permission_store_checked { get; construct; }

    public ScreenshotType screenshot_type { get; private set; default = ScreenshotType.ALL; }
    public bool grab_pointer { get; private set; default = false; }
    public bool redact_text { get; private set; default = false; }
    public int delay { get; private set; default = 0; }

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
        if (parent_window != "") {
            ((Gtk.Widget) this).realize.connect (() => {
                try {
                    ExternalWindow.from_handle (parent_window).set_parent_of (get_surface ());
                } catch (Error e) {
                    warning ("Failed to associate portal window with parent %s: %s", parent_window, e.message);
                }
            });
        }

        all_image = new Gtk.Image.from_icon_name ("grab-screen-symbolic");

        var all = new Gtk.CheckButton () {
            active = true,
            tooltip_text = _("Grab the whole screen")
        };
        all.add_css_class ("image-button");
        all_image.set_parent (all);

        all.toggled.connect (() => {
            if (all.active) {
                screenshot_type = ScreenshotType.ALL;
            }
        });

        var curr_image = new Gtk.Image.from_icon_name ("grab-window-symbolic");

        var curr_window = new Gtk.CheckButton () {
            group = all,
            tooltip_text = _("Grab the current window")
        };
        curr_window.add_css_class ("image-button");
        curr_image.set_parent (curr_window);

        curr_window.toggled.connect (() => {
            if (curr_window.active) {
                screenshot_type = ScreenshotType.WINDOW;
            }
        });

        var selection_image = new Gtk.Image.from_icon_name ("grab-area-symbolic");

        var selection = new Gtk.CheckButton () {
            group = all,
            tooltip_text = _("Select area to grab")
        };
        selection.add_css_class ("image-button");
        selection_image.set_parent (selection);

        selection.toggled.connect (() => {
            if (selection.active) {
                screenshot_type = ScreenshotType.AREA;
            }
        });

        var pointer_label = new Gtk.Label (_("Grab pointer:")) {
            halign = END
        };

        var pointer_switch = new Gtk.Switch () {
            halign = START
        };

        pointer_switch.activate.connect (() => {
            grab_pointer = pointer_switch.active;
        });

        var redact_label = new Gtk.Label (_("Conceal text:")) {
            halign = END
        };

        var redact_switch = new Gtk.Switch () {
            halign = START
        };

        redact_switch.activate.connect (() => {
            redact_text = redact_switch.active;
        });

        var delay_label = new Gtk.Label (_("Delay in seconds:"));
        delay_label.halign = Gtk.Align.END;

        var delay_spin = new Gtk.SpinButton.with_range (0, 15, 1);

        delay_spin.value_changed.connect (() => {
            delay = (int) delay_spin.value;
        });

        var take_btn = new Gtk.Button.with_label (_("Take Screenshot")) {
            receives_default = true
        };
        take_btn.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        take_btn.clicked.connect (() => {
            response (Gtk.ResponseType.OK);
        });

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

        option_grid.attach (redact_label, 0, 1);
        option_grid.attach (redact_switch, 1, 1);

        option_grid.attach (delay_label, 0, 2);
        option_grid.attach (delay_spin, 1, 2);

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

        var window_handle = new Gtk.WindowHandle () {
            child = box
        };

        child = window_handle;

        // We need to hide the title area
        titlebar = new Gtk.Grid () {
            visible = false
        };

        add_css_class ("dialog");
        add_css_class (Granite.STYLE_CLASS_MESSAGE_DIALOG);

        close_btn.clicked.connect (() => {
            response (Gtk.ResponseType.CLOSE);
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