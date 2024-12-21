/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class Screenshot.SetupDialog : Gtk.Window {
    public enum ScreenshotType {
        ALL,
        WINDOW,
        AREA
    }

    public signal void response (Gtk.ResponseType response_type);

    public string parent_window { get; construct; }

    public ScreenshotType screenshot_type { get; private set; default = ScreenshotType.ALL; }
    public bool grab_pointer { get; set; default = false; }
    public bool redact_text { get; set; default = false; }
    public int delay { get; private set; default = 0; }

    public SetupDialog (string parent_window, bool modal) {
        Object (
            resizable: false,
            parent_window: parent_window,
            modal: modal
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

        all_image = new Gtk.Image.from_icon_name ("grab-screen-symbolic") {
            icon_size = LARGE
        };

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

        var curr_image = new Gtk.Image.from_icon_name ("grab-window-symbolic") {
            icon_size = LARGE
        };

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

        var selection_image = new Gtk.Image.from_icon_name ("grab-area-symbolic") {
            icon_size = LARGE
        };

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

        var pointer_toggle = new Gtk.ToggleButton () {
            icon_name = "tools-pointer-symbolic",
            tooltip_text = _("Grab pointer")
        };
        pointer_toggle.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

        var redact_toggle = new Gtk.ToggleButton () {
            icon_name = "tools-redact-symbolic",
            tooltip_text = _("Conceal text")
        };
        redact_toggle.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

        var delay_image = new Gtk.Image.from_icon_name ("tools-timer-symbolic") {
            icon_size = LARGE,
            tooltip_text = _("Timer")
        };

        var delay_spin = new Gtk.SpinButton.with_range (0, 15, 1);

        delay_spin.value_changed.connect (() => {
            delay = (int) delay_spin.value;
        });

        var delay_label = new Gtk.Label (_("Delay in seconds:")) {
            halign = END,
            mnemonic_widget = delay_spin
        };

        var delay_box = new Gtk.Box (VERTICAL, 3);
        delay_box.append (delay_image);
        delay_box.append (delay_spin);

        var take_btn = new Gtk.Button.from_icon_name ("camera-photo-symbolic") {
            tooltip_text = _("Take Screenshot"),
            receives_default = true
        };
        take_btn.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

        take_btn.clicked.connect (() => {
            response (Gtk.ResponseType.OK);
        });

        var radio_box = new Gtk.Box (HORIZONTAL, 6) {
            halign = CENTER
        };
        radio_box.append (all);
        radio_box.append (curr_window);
        radio_box.append (selection);

        var box = new Gtk.Box (HORIZONTAL, 12) {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };
        box.append (new Gtk.WindowControls (START));
        box.append (radio_box);
        box.append (pointer_toggle);
        box.append (delay_box);
        box.append (redact_toggle);
        box.append (take_btn);

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

        var gtk_settings = Gtk.Settings.get_default ();
        gtk_settings.notify["gtk-application-prefer-dark-theme"].connect (() => {
            update_icons (gtk_settings.gtk_application_prefer_dark_theme);
        });

        update_icons (gtk_settings.gtk_application_prefer_dark_theme);

        pointer_toggle.bind_property ("active", this, "grab-pointer", SYNC_CREATE);
        redact_toggle.bind_property ("active", this, "redact-text", SYNC_CREATE);
    }

    private void update_icons (bool prefers_dark) {
        if (prefers_dark) {
            all_image.icon_name = "grab-screen-symbolic-dark";
        } else {
            all_image.icon_name = "grab-screen-symbolic";
        }
    }
}
