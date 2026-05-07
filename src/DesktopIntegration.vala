/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "io.elementary.gala.DesktopIntegration")]
public interface Gala.DesktopIntegration : Object {
    public struct RunningApplications {
        string app_id;
        HashTable<string, Variant> details;
    }

    public struct Window {
        uint64 uid;
        HashTable<string, Variant> details;
    }

    private const string NAME = "io.elementary.gala";
    private const string PATH = "/io/elementary/gala/DesktopInterface";

    public signal void running_applications_changed ();

    public abstract async RunningApplications[] get_running_applications () throws DBusError, IOError;
    public abstract async Window[] get_windows () throws DBusError, IOError;

    private static Gala.DesktopIntegration? instance;

    public static async Gala.DesktopIntegration? get_instance () {
        if (instance != null) {
            return instance;
        }

        try {
            instance = yield Bus.get_proxy (SESSION, NAME, PATH);
        } catch (Error e) {
            warning ("Cannot connect to compositor, portal working with reduced functionality.");
        }

        return instance;
    }
}
