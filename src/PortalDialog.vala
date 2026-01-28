/*
 * SPDX-FileCopyrightText: 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class PortalDialog : Gtk.Window, PantheonWayland.ExtendedBehavior {
    public string parent_handle { get; set; }

    construct {
        ((Gtk.Widget) this).realize.connect (on_realize);
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
