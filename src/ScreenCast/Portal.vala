/*
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 *
 * Authored by: Leonhard Kargl <leo.kargl@proton.me>
 */

[Flags]
public enum ScreenCast.SourceType {
    MONITOR = 1,
    WINDOW = 2,
    VIRTUAL = 4,
}

[Flags]
public enum ScreenCast.CursorMode {
    HIDDEN = 1,
    EMBEDDED = 2,
    METADATA = 4,
}

[DBus (name = "org.freedesktop.impl.portal.ScreenCast")]
public class ScreenCast.Portal : Object {
    public SourceType available_source_types { get; default = MONITOR | WINDOW | VIRTUAL; }
    public CursorMode available_cursor_modes { get; default = HIDDEN | EMBEDDED | METADATA; }
    public uint version { get; default = 3; }

    private DBusConnection connection;

    private HashTable<string, Session> sessions;

    public Portal (DBusConnection connection) {
        this.connection = connection;
        sessions = new HashTable<string, Session> (str_hash, str_equal);
    }

    public async void create_session (
        ObjectPath handle,
        ObjectPath session_handle,
        string app_id,
        HashTable<string, Variant> options,
        out uint response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        var session = new Session ();
        try {
            var session_register_id = connection.register_object (session_handle, session);
            sessions[session_handle] = session;
            session.closed.connect (() => {
                connection.unregister_object (session_register_id);
                sessions.remove (session_handle);
            });
        } catch (Error e) {
            warning ("Failed to export session object: %s", e.message);
            throw new DBusError.OBJECT_PATH_IN_USE (e.message);
        }

        if (!yield session.init ()) { // Todo: maybe allow cancelling via request object? In my test this didn't take longer than 100ms
            throw new IOError.FAILED ("Failed to create mutter ScreenCast session.");
        }

        response = 0;
        results = new HashTable<string, Variant> (str_hash, str_equal);
        results["session_id"] = Uuid.string_random ();
    }

    public async void select_sources (
        ObjectPath handle,
        ObjectPath session_handle,
        string app_id,
        HashTable<string, Variant> options,
        out uint response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        SourceType source_types = MONITOR;
        if ("types" in options) {
            source_types = (SourceType) options["types"];
        }

        bool multiple = false;
        if ("multiple" in options) {
            multiple = (bool) options["multiple"];
        }

        sessions[session_handle].select_sources (source_types, multiple);

        response = 0;
        results = new HashTable<string, Variant> (str_hash, str_equal);
    }

    public async void start (
        ObjectPath handle,
        ObjectPath session_handle,
        string app_id,
        string parent_window,
        HashTable<string, Variant> options,
        out uint response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {
        results = new HashTable<string, Variant> (str_hash, str_equal);

        var session = sessions[session_handle];

        uint _response = 2;
        Session.PipeWireStream[] streams = {};
        session.started.connect ((session_response, session_streams) => {
            _response = session_response;
            streams = session_streams;

            start.callback ();
        });

        session.start (parent_window);

        yield;

        if (_response == 2) {
            throw new IOError.FAILED ("Failed to get pipewire streams");
        }

        response = _response;
        results["streams"] = streams;
    }
}
