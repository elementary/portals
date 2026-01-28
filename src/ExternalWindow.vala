/*-
 * Copyright 2021-2022 elementary LLC <https://elementary.io>
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
    public abstract void set_parent_of (Gdk.Surface child_surface);

    public static ExternalWindow? from_handle (string handle) throws GLib.IOError {
        const string X11_PREFIX = "x11:";
        const string WAYLAND_PREFIX = "wayland:";
        ExternalWindow? external_window = null;

        if (handle.has_prefix (X11_PREFIX)) {
            external_window = new ExternalWindowX11 (handle.substring (X11_PREFIX.length));
        } else if (handle.has_prefix (WAYLAND_PREFIX)) {
            external_window = new ExternalWindowWayland (handle.substring (WAYLAND_PREFIX.length));
        } else {
            throw new IOError.FAILED ("Unhandled window type");
        }

        return external_window;
    }
}

public class ExternalWindowX11 : ExternalWindow, GLib.Object {
    private static Gdk.Display? x11_display = null;

    private X.Window foreign_window;

    public ExternalWindowX11 (string handle) throws GLib.IOError {
        unowned var display = get_x11_display ();
        if (display == null) {
            throw new IOError.FAILED ("No X display connection, ignoring X11 parent");
        }

        int xid;
        if (!int.try_parse (handle, out xid, null, 16)) {
            throw new IOError.FAILED ("Failed to reference external X11 window, invalid XID %s", handle);
        }

        foreign_window = xid;
    }

    private static unowned Gdk.Display get_x11_display () {
        if (x11_display != null) {
            return x11_display;
        }

        Gdk.set_allowed_backends ("x11");
        x11_display = Gdk.Display.open ("");
        Gdk.set_allowed_backends ("*");

        if (x11_display == null) {
            warning ("Failed to open X11 display");
        }

        return x11_display;
    }

    public void set_parent_of (Gdk.Surface child_surface) {
        unowned var display = (Gdk.X11.Display) get_x11_display ();
        unowned var x_display = display.get_xdisplay ();
        var child_xid = ((Gdk.X11.Surface) child_surface).get_xid ();

        x_display.set_transient_for_hint (child_xid, foreign_window);

        var dialog_atom = display.get_xatom_by_name ("_NET_WM_WINDOW_TYPE_DIALOG");
        x_display.change_property (
            child_xid,
            display.get_xatom_by_name ("_NET_WM_WINDOW_TYPE"),
            X.XA_ATOM,
            32,
            X.PropMode.Replace,
            (uchar[]) dialog_atom,
            1
        );
    }
}

public class ExternalWindowWayland : ExternalWindow, GLib.Object {
    private static Gdk.Display? wayland_display = null;

    private string handle;

    public ExternalWindowWayland (string handle) throws GLib.IOError {
        var display = get_wayland_display ();
        if (display == null) {
            throw new IOError.FAILED ("No Wayland display connection, ignoring Wayland parent");
        }

        this.handle = handle;
    }

    private static unowned Gdk.Display? get_wayland_display () {
        if (wayland_display != null) {
            return wayland_display;
        }

        Gdk.set_allowed_backends ("wayland");
        wayland_display = Gdk.Display.open (null);
        Gdk.set_allowed_backends ("*");

        if (wayland_display == null) {
            warning ("Failed to open Wayland display");
        }

        return wayland_display;
    }

    public void set_parent_of (Gdk.Surface child_surface) {
        if (!((Gdk.Wayland.Toplevel) child_surface).set_transient_for_exported (handle)) {
            warning ("Failed to set portal window transient for external parent");
        }
    }
}
