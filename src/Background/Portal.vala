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
            desktop_integration.running_applications_changed (() => running_applications_changed ());
        } catch {
            warning ("cannot connect to compositor, background portal working with reduced functionality");
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

    construct {
        try {
            desktop_integration = Bus.get_proxy_sync (BusType.SESSION, "org.pantheon.gala", "/org/pantheon/gala/DesktopInterface");
            desktop_integration.integration_running_applications_changed.connect (() => running_applications_changed ());
        } catch (Error e) {
            critical (e.message);
        }
    }

    private enum ApplicationState {
        BACKGROUND,
        RUNNING,
        ACTIVE
    }

    public HashTable<string, Variant> get_app_state () throws DBusError, IOError {
        if (desktop_integration == null) {
            throw new DBusError.FAILED ("no connection to compositor");
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

        var path = Path.build_filename (Environment.get_user_config_dir (), "autostart", app_id + ".desktop");

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
            warning ("failed to write autostart file: %s", e.message);
            return;
        }

        result = true;
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
