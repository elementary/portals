/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

 public class Screenshot.ApprovalDialog : Gtk.Window {
    public signal void response (Gtk.ResponseType response_type);

    public string parent_window { get; construct; }
    public string app_id { get; construct; }
    public string screenshot_uri { get; construct; }

    public ApprovalDialog (string parent_window, bool modal, string app_id, string screenshot_uri) {
        Object (
            resizable: false,
            parent_window: parent_window,
            modal: modal,
            app_id: app_id,
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

        var title = new Gtk.Label (_("Share Screenshot")) {
            max_width_chars = 0, // Wrap, but secondary label sets the width
            selectable = true,
            wrap = true,
            xalign = 0
        };
        title.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var subtitle = new Gtk.Label (_("Share this screenshot with the requesting app?")) {
            max_width_chars = 50,
            width_chars = 50, // Prevents a bug where extra height is preserved
            selectable = true,
            wrap = true,
            xalign = 0
        };

        if (app_id != null) {
            var app_info = new GLib.DesktopAppInfo (app_id + ".desktop");
            if (app_info != null) {
                subtitle.label = _("Share this screenshot with %s?").printf (app_info.get_display_name ());
            }
        }

        var screenshot_filename = GLib.Filename.from_uri (screenshot_uri);
        var screenshot_image = new Gtk.Picture.for_pixbuf (new Gdk.Pixbuf.from_file_at_scale (screenshot_filename, 384, 384, true)) {
        };

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
        box.add_css_class ("dialog-vbox");
        box.append (title);
        box.append (subtitle);
        box.append (screenshot_image);
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
