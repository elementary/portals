/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.gnome.Shell.Screenshot")]
public interface Gala.ScreenshotProxy : Object {
    public const string NAME = "org.gnome.Shell.Screenshot";
    public const string PATH = "/org/gnome/Shell/Screenshot";

    public abstract async void conceal_text () throws GLib.Error;
    public abstract async void screenshot (bool include_cursor, bool flash, string filename, out bool success, out string filename_used) throws GLib.Error;
    public abstract async void screenshot_window (bool include_frame, bool include_cursor, bool flash, string filename, out bool success, out string filename_used) throws GLib.Error;
    public abstract async void screenshot_area (int x, int y, int width, int height, bool flash, string filename, out bool success, out string filename_used) throws GLib.Error;
    public abstract async void screenshot_area_with_cursor (int x, int y, int width, int height, bool include_cursor, bool flash, string filename, out bool success, out string filename_used) throws GLib.Error;
    public abstract async void select_area (out int x, out int y, out int width, out int height) throws GLib.Error;
    public abstract async void pick_color (out HashTable<string, Variant> result) throws GLib.Error;
}

[DBus (name = "org.freedesktop.impl.portal.Screenshot")]
public class Screenshot.Portal : Object {
    private Gala.ScreenshotProxy screenshot_proxy;
    private DBusConnection connection;

    public uint32 version { get; default = 2; }

    public Portal (DBusConnection connection) {
        this.connection = connection;

        connection.get_proxy.begin<Gala.ScreenshotProxy> (
            Gala.ScreenshotProxy.NAME,
            Gala.ScreenshotProxy.PATH,
            NONE, null, (obj, res) => {
                try {
                    screenshot_proxy = connection.get_proxy.end<Gala.ScreenshotProxy> (res);
                } catch (GLib.Error e) {
                    warning ("Failed to get screenshot proxy, portal working with reduced functionality: %s", e.message);
                }
            }
        );
    }

    public async void screenshot (
        ObjectPath handle,
        string app_id,
        string parent_window,
        HashTable<string, Variant> options,
        out uint response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        var modal = true;
        var interactive = false;
        var permission_store_checked = false;

        if (options["modal"] != null && options["modal"].get_type_string () == "b") {
            modal = options["modal"].get_boolean ();
        }

        if (options["interactive"] != null && options["interactive"].get_type_string () == "b") {
            interactive = options["interactive"].get_boolean ();
        }

        if (options["permission_store_checked"] != null && options["permission_store_checked"].get_type_string () == "b") {
            permission_store_checked = options["permission_store_checked"].get_boolean ();
        }

        debug ("screenshot: modal=%b, interactive=%b, permission_store_checked=%b", modal, interactive, permission_store_checked);

        if (!interactive && permission_store_checked) {
            var success = false;
            var filename_used = "";

            try {
                yield screenshot_proxy.screenshot (false, true, "", out success, out filename_used);
            } catch (Error e) {
                warning ("Couldn't call screenshot: %s\n", e.message);
                response = 1;
                results = new HashTable<string, Variant> (str_hash, str_equal);
                return;
            }

            if (success) {
                response = 0;
                results = new HashTable<string, Variant> (str_hash, str_equal);
                results["filename"] = new Variant ("s", filename_used);
                return;
            } else {
                response = 1;
                results = new HashTable<string, Variant> (str_hash, str_equal);
                return;
            }
        }

        if (interactive) {
            var dialog = new Dialog (parent_window, modal, permission_store_checked);

            dialog.show ();
        }

        warning ("Unimplemented screenshot path, this should not be reached");
        response = 1;
        results = new HashTable<string, Variant> (str_hash, str_equal);
    }

    public async void pick_color (
        ObjectPath handle,
        string app_id,
        string parent_window,
        HashTable<string, Variant> options,
        out uint response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        var _result = new HashTable<string, Variant> (str_hash, str_equal);

        try {
            yield screenshot_proxy.pick_color (out _result);
        } catch (Error e) {
            warning ("Couldn't call pick_color: %s\n", e.message);
            response = 1;
            results = new HashTable<string, Variant> (str_hash, str_equal);
            results["color"] = new Variant.array (new GLib.VariantType ("d"), { 0.0, 0.0, 0.0 });
            return;
        }

        var color = _result["color"];
        if (color == null || color.get_type_string () != "(ddd)") {
            response = 2;
            results = new HashTable<string, Variant> (str_hash, str_equal);
            results["color"] = new Variant.array (new GLib.VariantType ("d"), { 0.0, 0.0, 0.0 });
            return;
        }

        response = 0;
        results = _result;
    }
}