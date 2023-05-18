/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Background")]
public class Background.Portal : Object {
    public signal void running_applications_changed ();

    private DBusConnection connection;
    private DesktopIntegration desktop_integration;

    public Portal (DBusConnection connection) {
        this.connection = connection;
        NotificationRequest.init (connection);
        try {
            desktop_integration = connection.get_proxy_sync ("org.pantheon.gala", "/org/pantheon/gala/DesktopInterface");
            desktop_integration.running_applications_changed.connect (() => running_applications_changed ());
        } catch {
            warning ("Cannot connect to compositor, background portal working with reduced functionality.");
        }
    }

    [DBus (name = "org.pantheon.gala.DesktopIntegration")]
    public interface DesktopIntegration : Object {
        public struct RunningApplications {
            string app_id;
            HashTable<string,Variant> details;
        }

        public signal void running_applications_changed ();
        public abstract RunningApplications[] get_running_applications () throws DBusError, IOError;
    }

    private enum ApplicationState {
        BACKGROUND,
        RUNNING,
        ACTIVE
    }

    public HashTable<string, Variant> get_app_state () throws DBusError, IOError {
        if (desktop_integration == null) {
            throw new DBusError.FAILED ("No connection to compositor.");
        }

        var apps = desktop_integration.get_running_applications ();
        var results = new HashTable<string, Variant> (null, null);
        foreach (var app in apps) {
            var app_id = app.app_id;
            if (app_id.has_suffix (".desktop")) {
                app_id = app_id.slice (0, app_id.last_index_of_char ('.'));
            }

            results[app_id] = ApplicationState.RUNNING; //FIXME: Don't hardcode: needs implementation on the gala side
        }

        return results;
    }

    public async void notify_background (
        ObjectPath handle,
        string app_id,
        string name,
        out uint32 response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        uint32 _response = 2;
        var _results = new HashTable<string, Variant> (str_hash, str_equal);

        var notification_request = new NotificationRequest ();

        notification_request.response.connect ((result) => {
            switch (result) {
                case NotificationRequest.NotifyBackgroundResult.CANCELLED:
                    _response = 1;
                    break;
                case NotificationRequest.NotifyBackgroundResult.FAILED:
                    break;
                default:
                    _response = 0;
                    _results["result"] = result;
                    break;
            }
            notify_background.callback ();
        });

        uint register_id = 0;
        try {
            register_id = connection.register_object<NotificationRequest> (handle, notification_request);
        } catch (Error e) {
            warning ("Failed to export request object: %s", e.message);
            throw new DBusError.OBJECT_PATH_IN_USE (e.message);
        }

        notification_request.send_notification (app_id, name);

        yield;

        connection.unregister_object (register_id);
        response = _response;
        results = _results;
    }

    private enum AutostartFlags {
        AUTOSTART_FLAGS_NONE,
        AUTOSTART_FLAGS_DBUS_ACTIVATABLE
    }

    public bool enable_autostart (
        string app_id,
        bool enable,
        string[] commandline,
        uint32 flags
    ) throws DBusError, IOError {
        /* If the portal request is made by a non-flatpak application app_id will most of the time be empty */
        if (app_id.strip () == "") {
            /* Usually we can then asume that the first commandline arg is the app_id */
            if (commandline[0].strip () != "") {
                app_id = commandline[0];
            } else {
                return false;
            }
        }

        var path = Path.build_filename (Environment.get_user_config_dir (), "autostart", app_id + ".desktop");

        if (!enable) {
            FileUtils.unlink (path);
            return false;
        }

        var autostart_flags = (AutostartFlags) flags;

        var key_file = new KeyFile ();
        key_file.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TYPE, "Application");
        key_file.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME, app_id);
        key_file.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_EXEC, flatpak_quote_argv (commandline));
        if (autostart_flags == AUTOSTART_FLAGS_DBUS_ACTIVATABLE) {
            key_file.set_boolean (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_DBUS_ACTIVATABLE, true);
        }
        key_file.set_string (KeyFileDesktop.GROUP, "X-Flatpak", app_id);

        try {
            key_file.save_to_file (path);
        } catch (Error e) {
            warning ("Failed to write autostart file: %s", e.message);
            return false;
        }

        return true;
    }

    private string flatpak_quote_argv (string[] argv) {
        var builder = new StringBuilder ();

        foreach (var arg in argv) {
            foreach (var c in (char[]) arg.data) {
                if (!c.isalnum () && !(c.to_string () in "-/~:._=@")) {
                    arg = Shell.quote (arg);
                    break;
                }
            }

            builder.append (arg);
            builder.append (" ");
        }

        return builder.str.strip ();
    }
}
