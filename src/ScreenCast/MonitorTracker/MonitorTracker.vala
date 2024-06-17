/*-
 * Copyright (c) 2018 elementary LLC.
 *
 * This software is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class ScreenCast.MonitorTracker : GLib.Object {
    public Gee.LinkedList<ScreenCast.Monitor> monitors { get; construct; }

    private MutterDisplayConfigInterface iface;
    private uint current_serial;

    construct {
        monitors = new Gee.LinkedList<ScreenCast.Monitor> ();
        try {
            iface = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.Mutter.DisplayConfig", "/org/gnome/Mutter/DisplayConfig");
            iface.monitors_changed.connect (get_monitor_config);
            get_monitor_config ();
        } catch (Error e) {
            critical (e.message);
        }
    }

    public void get_monitor_config () {
        MutterReadMonitor[] mutter_monitors;
        MutterReadLogicalMonitor[] mutter_logical_monitors;
        GLib.HashTable<string, GLib.Variant> properties;
        try {
            iface.get_current_state (out current_serial, out mutter_monitors, out mutter_logical_monitors, out properties);
        } catch (Error e) {
            critical (e.message);
        }

        foreach (var mutter_monitor in mutter_monitors) {
            var monitor = get_monitor_by_hash (mutter_monitor.monitor.hash);
            if (monitor == null) {
                monitor = new ScreenCast.Monitor ();
                monitors.add (monitor);
            }

            monitor.connector = mutter_monitor.monitor.connector;
            monitor.vendor = mutter_monitor.monitor.vendor;
            monitor.product = mutter_monitor.monitor.product;
            monitor.serial = mutter_monitor.monitor.serial;
            var display_name_variant = mutter_monitor.properties.lookup ("display-name");
            if (display_name_variant != null) {
                monitor.display_name = display_name_variant.get_string ();
            } else {
                monitor.display_name = monitor.connector;
            }

            var is_builtin_variant = mutter_monitor.properties.lookup ("is-builtin");
            if (is_builtin_variant != null) {
                monitor.is_builtin = is_builtin_variant.get_boolean ();
            } else {
                /*
                 * Absence of "is-builtin" means it's not according to the documentation.
                 */
                monitor.is_builtin = false;
            }
        }
    }

    private ScreenCast.Monitor? get_monitor_by_hash (uint hash) {
        foreach (var monitor in monitors) {
            if (monitor.hash == hash) {
                return monitor;
            }
        }

        return null;
    }
}
