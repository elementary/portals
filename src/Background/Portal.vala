/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Background")]
public class Background.Portal : Object {
    public signal void running_applications_changed ();

    private const string ACTION_ALLOW_BACKGROUND = "background.allow";
    private const string ACTION_FORBID_BACKGROUND = "background.forbid";

    private DBusConnection connection;
    private DesktopIntegration desktop_integration;

    public Portal (DBusConnection connection) {
        this.connection = connection;
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

    private enum NotifyBackgroundResult {
        FORBID = 0,
        ALLOW = 1,
        ALLOW_ONCE = 2
    }

    public async void notify_background (
        ObjectPath handle,
        string app_id,
        string name,
        out uint32 response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        var _results = new HashTable<string, Variant> (str_hash, str_equal);

        var notification = new Notify.Notification (
            _("Background activity"),
            _(""""%s" is running in the background""").printf (name),
            "dialog-information"
        );

        notification.add_action (ACTION_ALLOW_BACKGROUND, _("Allow"), () => {
            _results.set ("result", NotifyBackgroundResult.ALLOW);
            notify_background.callback ();
        });

        notification.add_action (ACTION_FORBID_BACKGROUND, _("Forbid"), () => {
            _results.set ("result", NotifyBackgroundResult.FORBID);
            notify_background.callback ();
        });

        notification.closed.connect (() => {
            _results.set ("result", NotifyBackgroundResult.ALLOW_ONCE);
            notify_background.callback ();
        });

        try {
            notification.show ();
        } catch (Error e) {
            critical ("Failed to send background notification for %s: %s", app_id, e.message);
        }

        yield;

        response = 0; //Won't be used
        results = _results;
    }

    private enum AutostartFlags {
        AUTOSTART_FLAGS_NONE = 0,
        AUTOSTART_FLAGS_DBUS_ACTIVATABLE = 1
    }

    public bool enable_autostart (
        string app_id,
        bool enable,
        string[] commandline,
        uint32 flags
    ) throws DBusError, IOError {
        /* If the portal request is made by a non-flatpaked application app_id will most of the time be empty */
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
