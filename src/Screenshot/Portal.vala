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

    // Force the property name to be "version" instead of "Version"
    [DBus (name = "version")]
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

    private async void do_delay (int seconds) {
        if (seconds > 0) {
            GLib.Timeout.add_seconds (seconds, () => {
                do_delay.callback ();
                return false;
            });

            yield;
        }
    }

    private async string do_screenshot (
        SetupDialog.ScreenshotType screenshot_type,
        bool grab_pointer,
        bool redact,
        int delay
    ) throws GLib.Error {
        string filename_used = "";
        switch (screenshot_type) {
            case SetupDialog.ScreenshotType.ALL:
                var success = false;

                yield do_delay (delay);
                yield screenshot_proxy.screenshot (grab_pointer, true, "/tmp/portal_screenshot.png", out success, out filename_used);

                if (!success) {
                    throw new GLib.IOError.FAILED ("Failed to take screenshot");
                }

                break;
            case SetupDialog.ScreenshotType.WINDOW:
                var success = false;

                yield do_delay (delay);
                yield screenshot_proxy.screenshot_window (false, grab_pointer, true, "/tmp/portal_screenshot.png", out success, out filename_used);

                if (!success) {
                    throw new GLib.IOError.FAILED ("Failed to take screenshot");
                }

                break;
            case SetupDialog.ScreenshotType.AREA:
                var success = false;

                int x, y, width, height;
                yield screenshot_proxy.select_area (out x, out y, out width, out height);

                yield do_delay (delay);
                yield screenshot_proxy.screenshot_area (x, y, width, height, true, "/tmp/portal_screenshot.png", out success, out filename_used);

                if (!success) {
                    throw new GLib.IOError.FAILED ("Failed to take screenshot");
                }

                break;
        }

        return GLib.Filename.to_uri (filename_used, null);
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

        if ("modal" in options && options["modal"].get_type_string () == "b") {
            modal = options["modal"].get_boolean ();
        }

        if ("interactive" in options && options["interactive"].get_type_string () == "b") {
            interactive = options["interactive"].get_boolean ();
        }

        if ("permission_store_checked" in options && options["permission_store_checked"].get_type_string () == "b") {
            permission_store_checked = options["permission_store_checked"].get_boolean ();
        }

        debug ("screenshot: modal=%b, interactive=%b, permission_store_checked=%b", modal, interactive, permission_store_checked);

        // Non-interactive screenshots for a pre-approved app, just take a fullscreen screenshot and send it
        if (!interactive && permission_store_checked) {
            var uri = "";

            try {
                uri = yield do_screenshot (SetupDialog.ScreenshotType.ALL, false, false, 0);
            } catch (Error e) {
                warning ("Couldn't call screenshot: %s\n", e.message);
                response = 1;
                results = new HashTable<string, Variant> (str_hash, str_equal);
                return;
            }

            response = 0;
            results = new HashTable<string, Variant> (str_hash, str_equal);
            results["uri"] = uri;
            return;
        }

        if (!interactive && !permission_store_checked) {
            var uri = "";

            try {
                uri = yield do_screenshot (SetupDialog.ScreenshotType.ALL, false, false, 0);
            } catch (Error e) {
                warning ("Couldn't call screenshot: %s\n", e.message);
                response = 1;
                results = new HashTable<string, Variant> (str_hash, str_equal);
                return;
            }

            // This app has not been pre-approved to take screenshots, so we prompt the user
            var dialog = new ApprovalDialog (parent_window, modal, app_id, uri);

            bool cancelled = true;
            dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.OK) {
                    cancelled = false;
                }

                screenshot.callback ();
            });

            dialog.show ();
            yield;


            dialog.destroy ();

            if (cancelled) {
                response = 1;
                results = new HashTable<string, Variant> (str_hash, str_equal);
                return;
            } else {
                response = 0;
                results = new HashTable<string, Variant> (str_hash, str_equal);
                results["uri"] = uri;
                return;
            }
        }

        if (interactive) {
            var dialog = new SetupDialog (parent_window, modal);

            bool cancelled = true;
            dialog.response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.OK) {
                    cancelled = false;
                }

                screenshot.callback ();
            });

            dialog.show ();
            yield;

            dialog.destroy ();

            if (cancelled) {
                response = 1;
                results = new HashTable<string, Variant> (str_hash, str_equal);
                return;
            }

            var uri = "";
            try {
                uri = yield do_screenshot (dialog.screenshot_type, dialog.grab_pointer, dialog.redact_text, dialog.delay);
            } catch (Error e) {
                warning ("Couldn't call screenshot: %s\n", e.message);
                response = 2;
                results = new HashTable<string, Variant> (str_hash, str_equal);
                return;
            }

            // The user has already approved this app to take screenshots, so we send the screenshot without prompting
            if (permission_store_checked) {
                response = 0;
                results = new HashTable<string, Variant> (str_hash, str_equal);
                results["uri"] = uri;
                return;
            } else {
                // This app has not been pre-approved to take screenshots, so we prompt the user
                var approval_dialog = new ApprovalDialog (parent_window, modal, app_id, uri);

                bool approval_cancelled = true;
                approval_dialog.response.connect ((response_id) => {
                    if (response_id == Gtk.ResponseType.OK) {
                        approval_cancelled = false;
                    }

                    screenshot.callback ();
                });

                approval_dialog.show ();
                yield;

                approval_dialog.destroy ();

                if (approval_cancelled) {
                    response = 1;
                    results = new HashTable<string, Variant> (str_hash, str_equal);
                    return;
                } else {
                    response = 0;
                    results = new HashTable<string, Variant> (str_hash, str_equal);
                    results["uri"] = uri;
                    return;
                }
            }
        }

        warning ("Unimplemented screenshot code path, this should not be reached");
        response = 2;
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