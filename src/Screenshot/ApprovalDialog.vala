/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

 public class Screenshot.ApprovalDialog : Gtk.Window {
    public signal void response (Gtk.ResponseType response_type);

    public string parent_window { get; construct; }
    public string screenshot_uri { get; construct; }

    public ApprovalDialog (string parent_window, bool modal, string screenshot_uri) {
        Object (
            resizable: false,
            parent_window: parent_window,
            modal: modal,
            screenshot_uri: screenshot_uri
        );
    }

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

        // TODO: Add a screenshot preview and wording

        var allow_button = new Gtk.Button.with_label (_("Share Screenshot")) {
            receives_default = true
        };
        allow_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        allow_button.clicked.connect (() => {
            response (Gtk.ResponseType.OK);
        });

        var close_btn = new Gtk.Button.with_label (_("Close"));

        var actions = new Gtk.Box (HORIZONTAL, 6) {
            halign = END,
            homogeneous = true
        };
        actions.append (close_btn);
        actions.append (allow_button);

        var box = new Gtk.Box (VERTICAL, 24) {
            margin_top = 24,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };
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