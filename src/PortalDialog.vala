/*
 * SPDX-FileCopyrightText: 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class PortalDialog : Gtk.Window, PantheonWayland.ExtendedBehavior {
    /**
     * The {@link GLib.Icon} that is used to display the image
     * on the left side of the dialog.
     */
    public GLib.Icon image_icon { get; set; }

    /**
     * The {@link GLib.Icon} that is used to display a badge, bottom-end aligned,
     * over the image on the left side of the dialog.
     */
    public GLib.Icon badge_icon { get; set; }

    /**
     * The secondary text, body of the dialog.
     */
    public string secondary_text { get; set; }

    /**
     * The child widget for the content area
     */
    public Gtk.Widget content { get; set; }

    /**
     * The parent window identifier as described by https://flatpak.github.io/xdg-desktop-portal/docs/window-identifiers.html
     */
    public string parent_handle { get; set; }

    private Granite.Box button_box;

    construct {
        var image = new Gtk.Image () {
            icon_size = LARGE
        };

        var badge = new Gtk.Image () {
            icon_size = NORMAL,
            halign = END,
            valign = END
        };

        var overlay = new Gtk.Overlay () {
            child = image,
            valign = START
        };
        overlay.add_overlay (badge);

        var header_label = new Granite.HeaderLabel ("") {
            size = H3
        };

        var header = new Granite.Box (HORIZONTAL);
        header.append (overlay);
        header.append (header_label);

        button_box = new Granite.Box (HORIZONTAL, HALF) {
            halign = END,
            homogeneous = true
        };

        var toolbarview = new Granite.ToolBox ();
        toolbarview.add_bottom_bar (button_box);
        toolbarview.add_top_bar (header);

        child = toolbarview;

        default_height = 400;
        default_width = 350;
        modal = true;

        // We need to hide the title area
        titlebar = new Gtk.Grid () {
            visible = false
        };

        add_css_class ("dialog");

        bind_property ("image-icon", image, "gicon");
        bind_property ("badge-icon", badge, "gicon");
        bind_property ("content", toolbarview, "content");
        bind_property ("title", header_label, "label");
        bind_property ("secondary-text", header_label, "secondary-text");
        ((Gtk.Widget) this).realize.connect (on_realize);
    }

    public Gtk.Button add_button (string button_text) {
        var button = new Gtk.Button.with_label (button_text);
        button_box.append (button);

        return button;
    }

    private void on_realize () {
        unowned var toplevel = (Gdk.Toplevel) get_surface ();

        if (parent_handle != "") {
            try {
                ExternalWindow.from_handle (parent_handle).set_parent_of (toplevel);
            } catch (Error e) {
                warning ("Failed to associate portal window with parent '%s': %s", parent_handle, e.message);
                make_sticky ();
            }
        } else {
            make_sticky ();
        }
    }

    private void make_sticky () {
        child.realize.connect (() => {
            connect_to_shell ();
            make_centered ();
            set_keep_above ();
        });
    }
}
