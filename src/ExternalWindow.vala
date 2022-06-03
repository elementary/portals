/*-
 * Copyright 2021 elementary LLC <https://elementary.io>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor
 * Boston, MA 02110-1335 USA.
 *
 * Authored by: David Hewitt <davidmhewitt@gmail.com>
 */

public interface ExternalWindow : GLib.Object {
    public abstract void set_parent_of (Gtk.Window child_window) throws IOError;

    public static ExternalWindow? from_handle (string handle) {
        const string X11_PREFIX = "x11:";
        if (handle.has_prefix (X11_PREFIX)) {
            var external_window_x11 = new ExternalWindowX11 (handle.substring (X11_PREFIX.length));
            return external_window_x11;
        }

        // TODO: Handle Wayland

        warning ("Unhandled parent window type %s", handle);

        return null;
    }
}

public class ExternalWindowX11 : ExternalWindow, GLib.Object {

    public string handle { get; construct; }
    private X.Window? parent_window = null;

    public ExternalWindowX11 (string handle) {
        Object (handle: handle);
    }

    construct {
        int xid;
        int.try_parse (handle, out xid, null, 16);
        parent_window = (X.Window) xid;
    }

    public void set_parent_of (Gtk.Window child_window) throws IOError {
        if (parent_window == null) {
            throw new IOError.FAILED ("Failed to reference external X11 window, invalid XID %s", handle);
        }

        unowned var child_surface = (Gdk.X11.Surface) child_window.get_surface ();
        unowned var child_display = (Gdk.X11.Display) child_surface.get_display ();
        unowned var child_xdisplay = child_display.get_xdisplay ();

        // Render dialog on top of parent_window:
        X.WindowAttributes parent_window_attributes;
        child_xdisplay.get_window_attributes (parent_window, out parent_window_attributes);
        child_xdisplay.reparent_window (
            child_surface.get_xid (),
            parent_window,
            (parent_window_attributes.width - child_window.default_width) / 2,
            (parent_window_attributes.height - child_window.default_height) / 2
        );
    }
}
