/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Background")]
public class Background.Portal : Object {
    public signal void running_applications_changed ();

    private Gala.DesktopIntegration? desktop_integration;
    private DBusConnection connection;

    public Portal (DBusConnection connection) {
        this.connection = connection;

        Gala.DesktopIntegration.get_instance.begin ((obj, res) => {
            desktop_integration = Gala.DesktopIntegration.get_instance.end (res);

            if (desktop_integration != null) {
                desktop_integration.running_applications_changed.connect (() => running_applications_changed ());
            }
        });
    }

    [CCode (type_signature = "u")]
    private enum ApplicationState {
        BACKGROUND,
        RUNNING,
        ACTIVE
    }

    public async HashTable<string, Variant> get_app_state () throws DBusError, IOError {
        if (desktop_integration == null) {
            throw new DBusError.FAILED ("No connection to compositor.");
        }

        var results = new HashTable<string, Variant> (null, null);
        debug ("getting application states");

        foreach (var app in yield desktop_integration.get_running_applications ()) {
            var app_id = app.app_id;
            if (app_id.has_suffix (".desktop")) {
                app_id = app_id.slice (0, app_id.last_index_of_char ('.'));
            }

            var app_state = ApplicationState.RUNNING; //FIXME: Don't hardcode: needs implementation on the gala side
            debug ("App state of '%s' set to %u (= %s).", app_id, app_state, app_state.to_string ());
            results[app_id] = app_state;
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
        debug ("Notify background for '%s'.", app_id);

        var _results = new HashTable<string, Variant> (str_hash, str_equal);
        uint32 _response = 2;

        var notification = new NotificationRequest ();
        notification.response.connect ((result) => {
            if (result == CANCELLED) {
                _response = 1;
            } else if (result != FAILED) {
                _response = 0;
                _results["result"] = result;
            }

            debug ("Response to background activity of '%s': %s.", app_id, result.to_string ());
            notify_background.callback ();
        });

        uint register_id = 0;
        try {
            register_id = connection.register_object<NotificationRequest> (handle, notification);
        } catch (Error e) {
            warning ("Failed to export request object: %s", e.message);
            throw new DBusError.OBJECT_PATH_IN_USE (e.message);
        }

        debug ("Sending desktop notification for '%s'.", app_id);
        try {
            yield notification.send_notification (app_id, name);
            yield;
        } catch (Error e) {
            warning ("Failed to notify about background activity from '%s': %s", app_id, e.message);
        }

        connection.unregister_object (register_id);
        response = _response;
        results = _results;
    }

    [Flags]
    public enum AutostartFlags {
        NONE,
        DBUS_ACTIVATABLE
    }

    public async bool enable_autostart (
        string app_id,
        bool enable,
        string[] commandline,
        AutostartFlags flags
    ) throws DBusError, IOError {
        /* If the portal request is made by a non-flatpak application app_id will most of the time be empty
         * We then use the commandline as a fallback.
         */
        var _app_id = app_id;
        if (_app_id == "") {
            _app_id = commandline[0].strip ();
        }

        /* Validate app_id by creating a DesktopAppInfo and fall back to full commandline.
         * If eg commandline[0] is "sudo" or "/usr/bin/python3"
         */
        var app_info = new DesktopAppInfo (_app_id + ".desktop");
        if (app_info == null) {
            _app_id = string.joinv ("-", commandline).replace ("--", "-").replace ("--", "-");
        }

        var autostart_dir = File.new_build_filename (Environment.get_user_config_dir (), "autostart");
        var file = autostart_dir.get_child (_app_id + ".desktop");
        if (!enable) {
            try { yield file.delete_async (); } catch {}
            return false;
        }

        if (!autostart_dir.query_exists ()) {
            try {
                yield autostart_dir.make_directory_async ();
            } catch (Error e) {
                warning ("Failed to make autostart directory: %s", e.message);
                throw new DBusError.FAILED (e.message);
            }
        }

        var key_file = new KeyFile ();

        if (file.query_exists ()) {
            try {
                uint8[] contents;
                yield file.load_contents_async (null, out contents, null);

                key_file.load_from_data ((string) contents, contents.length, KEEP_COMMENTS | KEEP_TRANSLATIONS);
            } catch (Error e) {
                warning ("Failed to load exisiting autostart file: %s", e.message);
            }
        }

        key_file.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_TYPE, KeyFileDesktop.TYPE_APPLICATION);

        if (app_info != null) {
            key_file.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME, app_info.get_display_name ());
            key_file.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON, app_info.get_string (KeyFileDesktop.KEY_ICON));
            key_file.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_COMMENT, app_info.get_description ());
        } else {
            key_file.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_NAME, _("Custom Command"));
            key_file.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_ICON, "application-default-icon");
            key_file.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_COMMENT, string.joinv (" ", commandline));
        }

        key_file.set_string (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_EXEC, quote_argv (commandline));
        key_file.set_boolean (KeyFileDesktop.GROUP, KeyFileDesktop.KEY_DBUS_ACTIVATABLE, flags == DBUS_ACTIVATABLE);

        if (app_id != "") {
            key_file.set_string (KeyFileDesktop.GROUP, "X-Flatpak", app_id);
        }

        FileCreateFlags create_flags = PRIVATE | REPLACE_DESTINATION;
        var contents = key_file.to_data ();

        try {
            try {
                yield file.replace_contents_async (contents.data, null, true, create_flags, null, null);
            } catch (IOError.CANT_CREATE_BACKUP e) {
                yield file.replace_contents_async (contents.data, null, false, create_flags, null, null);
            }
        } catch (Error e) {
            warning ("Failed to write autostart file: %s", e.message);
            throw new DBusError.FAILED (e.message);
        }

        debug ("Autostart file installed at '%s'.", file.get_path ());
        return true;
    }

    private string quote_argv (string[] argv) {
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
