/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

 public class Screenshot.ApprovalDialog : Granite.MessageDialog {
    public string parent_window { get; construct; }
    public string screenshot_uri { get; construct; }

    public ApprovalDialog (string parent_window, bool modal, string app_id, string screenshot_uri) {
        Object (
            parent_window: parent_window,
            modal: modal,
            screenshot_uri: screenshot_uri,
            primary_text: _("Share this screenshot with the requesting app?"),
            secondary_text: _("Only the app which requested this screenshot will be able to see it. This screenshot will not be saved elsewhere."),
            buttons: Gtk.ButtonsType.CANCEL
        );

        if (app_id != null) {
            var app_info = new GLib.DesktopAppInfo (app_id + ".desktop");
            if (app_info != null) {
                primary_text = _("Share this screenshot with “%s”?").printf (app_info.get_display_name ());
            }
        }
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

        image_icon = new ThemedIcon ("io.elementary.screenshot");

        var screenshot_filename = GLib.Filename.from_uri (screenshot_uri);
        var screenshot_image = new Gtk.Picture.for_pixbuf (new Gdk.Pixbuf.from_file_at_scale (screenshot_filename, 400, 400, true)) {
            overflow = HIDDEN,
            width_request = 400
        };
        screenshot_image.add_css_class (Granite.STYLE_CLASS_CARD);
        screenshot_image.add_css_class (Granite.STYLE_CLASS_ROUNDED);
        screenshot_image.add_css_class (Granite.STYLE_CLASS_CHECKERBOARD);

        var allow_button = add_button (_("Share Screenshot"), Gtk.ResponseType.OK);
        allow_button.receives_default = true;
        allow_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        custom_bin.append (screenshot_image);
    }
}
