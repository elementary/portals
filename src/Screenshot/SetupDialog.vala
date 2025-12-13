/*
 * SPDX-FileCopyrightText: 2023-2025 elementary, Inc. (https://elementary.io)
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

    public ScreenshotType screenshot_type { get; set; default = ALL; }
    public bool grab_pointer { get; private set; default = false; }
    public bool redact_text { get; private set; default = false; }
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

        var type_action = new SimpleAction.stateful ("type", VariantType.UINT32, new Variant.uint32 (screenshot_type));
        type_action.activate.connect ((parameter) => {
            screenshot_type = (ScreenshotType) parameter.get_uint32 ();
        });

        notify ["screenshot-type"].connect (() => {
            type_action.set_state (new Variant.uint32 (screenshot_type));
        });

        var action_group = new SimpleActionGroup ();
        action_group.add_action (type_action);

        insert_action_group ("screenshot", action_group);

        all_image = new Gtk.Image.from_icon_name ("grab-screen-symbolic") {
            icon_size = LARGE
        };

        var all_label = new Gtk.Label (_("Screen")) ;
        all_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var all_box = new Gtk.Box (VERTICAL, 3);
        all_box.append (all_image);
        all_box.append (all_label);

        var all = new Gtk.CheckButton () {
            action_name = "screenshot.type",
            action_target = new Variant.uint32 (ScreenshotType.ALL),
            child = all_box
        };
        all.add_css_class ("image-button");

        var curr_image = new Gtk.Image.from_icon_name ("grab-window-symbolic") {
            icon_size = LARGE
        };

        var curr_label = new Gtk.Label (_("Window"));
        curr_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var curr_box = new Gtk.Box (VERTICAL, 3);
        curr_box.append (curr_image);
        curr_box.append (curr_label);

        var curr_window = new Gtk.CheckButton () {
            action_name = "screenshot.type",
            action_target = new Variant.uint32 (ScreenshotType.WINDOW),
            child = curr_box,
            group = all
        };
        curr_window.add_css_class ("image-button");

        var selection_image = new Gtk.Image.from_icon_name ("grab-area-symbolic") {
            icon_size = LARGE
        };

        var selection_label = new Gtk.Label (_("Area"));
        selection_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var selection_box = new Gtk.Box (VERTICAL, 3);
        selection_box.append (selection_image);
        selection_box.append (selection_label);

        var selection = new Gtk.CheckButton () {
            action_name = "screenshot.type",
            action_target = new Variant.uint32 (ScreenshotType.AREA),
            child = selection_box,
            group = all
        };
        selection.add_css_class ("image-button");

        var pointer_switch = new Gtk.Switch () {
            halign = START
        };

        pointer_switch.state_set.connect (() => {
            grab_pointer = pointer_switch.active;
        });

        var pointer_label = new Gtk.Label (_("Grab pointer:")) {
            halign = END,
            mnemonic_widget = pointer_switch
        };

        var delay_spin = new Gtk.SpinButton.with_range (0, 15, 1);

        delay_spin.value_changed.connect (() => {
            delay = (int) delay_spin.value;
        });

        var delay_label = new Gtk.Label (_("Delay in seconds:")) {
            halign = END,
            mnemonic_widget = delay_spin
        };

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

        if (Utils.get_redacted_font_available ()) {
            var redact_switch = new Gtk.Switch () {
                halign = START
            };

            redact_switch.state_set.connect (() => {
                redact_text = redact_switch.active;
            });

            var redact_label = new Gtk.Label (_("Conceal text:")) {
                halign = END,
                mnemonic_widget = redact_switch
            };

            option_grid.attach (redact_label, 0, 1);
            option_grid.attach (redact_switch, 1, 1);
        }

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
    }
}
