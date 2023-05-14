/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
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
    }

    public struct RunningApplication {
        string app_id;
        GLib.HashTable<string, Variant> details;
    }

    [DBus (name = "org.pantheon.gala.DesktopIntegration")]
    public interface DesktopIntegration : GLib.Object {
        [DBus (name = "RunningApplicationsChanged")]
        public abstract signal void integration_running_applications_changed ();
        [DBus (name = "GetRunningApplications")]
        public abstract void get_running_applications (out RunningApplication[] running_apps) throws DBusError, IOError;
    }

    construct {
        try {
            desktop_integration = Bus.get_proxy_sync (BusType.SESSION, "org.pantheon.gala", "/org/pantheon/gala/DesktopInterface");
            desktop_integration.integration_running_applications_changed.connect (() => running_applications_changed ());
        } catch (Error e) {
            critical (e.message);
        }
    }

    private enum WindowState {
        BACKGROUND = 0, //No open window
        RUNNING = 1, //At least one open window
        ACTIVE = 2 //In the foreground
    }

    public void get_app_state (out HashTable<string, Variant> apps) throws DBusError, IOError {
        apps = new HashTable<string, Variant> (str_hash, str_equal);

        try {
            RunningApplication[] result = {};
            desktop_integration.get_running_applications (out result);
            for (int i = 0; i < result.length; i++) {
                var app_id = result[i].app_id.strip ();
                if (app_id.has_suffix (".desktop")) {
                    var index = app_id.last_index_of (".desktop");
                    app_id = app_id.slice (0, index);
                }
                apps.set (app_id, WindowState.RUNNING); //FIXME: Don't hardcode: needs implementation on the gala side
            }
        } catch (Error e) {
            critical (e.message);
        }
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

    public void enable_autostart (
        string app_id,
        bool enable,
        string[] commandline,
        uint32 flags,
        out bool result
    ) throws DBusError, IOError {
        result = false;

        /* If the portal request is made by a non-flatpaked application app_id will most of the time be empty */
        if (app_id.strip () == "") {
            /* Usually we can then asume that the first commandline arg is the app_id
               but just to be sure we only do this with our own (io.elementary.APP) ones.
               The reason we do this at all are primarily mail, calendar and tasks, which need to autostart
               but currently can't be shipped as flatpaks, so this is useful to not have to care about that stuff
               in the respective apps and even allow user intervention */
            if (commandline[0].contains ("io.elementary.")) {
                app_id = commandline[0];
            } else {
                return;
            }
        }

        string file_name = app_id + ".desktop";
        string directory = Path.build_filename (Environment.get_user_config_dir (), "autostart");
        string full_path = Path.build_filename (directory, file_name);

        if (!enable) {
            FileUtils.unlink (full_path);
            return;
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
            key_file.save_to_file (full_path);
        } catch (Error e) {
            critical (e.message);
            return;
        }

        result = true;
    }

    private string flatpak_quote_argv (string[] argv) {
        var builder = new StringBuilder ();

        for (int i = 0; i < argv.length; i++) {
            if (i != 0) {
                builder.append (" ");
            }

            var str = argv[i];

            for (int j = 0; j < str.char_count (); j++) {
                char c = str.get (str.index_of_nth_char (j));
                if (!c.isalnum () &&
                    !(c == '-' || c == '/' || c == '~' ||
                    c == ':' || c == '.' || c == '_' ||
                    c == '=' || c == '@')) {
                    str = Shell.quote (str);
                    break;
                }
            }

            builder.append (str);
        }

        return builder.str;
    }
}
