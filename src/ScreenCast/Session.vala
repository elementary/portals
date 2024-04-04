
[DBus (name = "org.gnome.Mutter.ScreenCast")]
private interface Mutter.ScreenCast : Object {
    public abstract async ObjectPath create_session (HashTable<string, Variant> options);
}

[DBus (name = "org.gnome.Mutter.ScreenCast.Session")]
private interface Mutter.ScreenCastSession : Object {
    public signal void closed ();

    public abstract async ObjectPath record_area (int x, int y, int width, int height, HashTable<string, Variant> properties) throws DBusError, IOError;
    public abstract async ObjectPath record_monitor (string connector, HashTable<string, Variant> properties) throws DBusError, IOError;
    public abstract async ObjectPath record_virtual (HashTable<string, Variant> properties) throws DBusError, IOError;
    public abstract async ObjectPath record_window (HashTable<string, Variant> properties) throws DBusError, IOError;

    public abstract async void start () throws DBusError, IOError;
    public abstract async void stop () throws DBusError, IOError;
}

[DBus (name = "org.gnome.Mutter.ScreenCast.Stream")]
private interface Mutter.ScreenCastStream : Object {
    public abstract HashTable<string, Variant> parameters { owned get; }

    public signal void pipe_wire_stream_added (uint node_id);

    public abstract async void start () throws DBusError, IOError;
}

[DBus (name = "org.freedesktop.impl.portal.Session")]
public class ScreenCast.Session : Object {
    public struct PipeWireStream {
        uint node_id;
        HashTable<string, Variant> properties;
    }

    public signal void closed (HashTable<string, Variant> details);

    internal signal void started (PipeWireStream[] streams);

    public uint version { get; default = 1; }

    private Mutter.ScreenCastSession session;

    private SourceType source_types;
    private bool allow_multiple;

    private PipeWireStream[] streams;
    private int required_streams = 0;

    internal async bool init () {
        Mutter.ScreenCast proxy;
        try {
            proxy = yield Bus.get_proxy (SESSION, "org.gnome.Mutter.ScreenCast", "/org/gnome/Mutter/ScreenCast");
        } catch (Error e) {
            critical ("Failed to get proxy: %s", e.message);
            return false;
        }

        string session_handle;
        try {
            session_handle = yield proxy.create_session (new HashTable<string, Variant> (str_hash, str_equal));
        } catch (Error e) {
            critical ("Failed to create session: %s", e.message);
            return false;
        }

        try {
            session = yield Bus.get_proxy (SESSION, "org.gnome.Mutter.ScreenCast", session_handle);
        } catch (Error e) {
            critical ("Failed to get session object: %s", e.message);
            return false;
        }

        return true;
    }

    internal void select_sources (SourceType source_types, bool allow_multiple) {
        this.source_types = source_types;
        this.allow_multiple = allow_multiple;
    }

    internal async void start () {
        //do selection, etc.
        //we want virtual

        if (VIRTUAL in source_types) {
            required_streams++;
            yield record_virtual ();
        }

        if (MONITOR in source_types) {
            required_streams++;
            yield select_monitor ();
        }

        try {
            yield session.start ();
        } catch (Error e) {
            warning ("Failed to start mutter session: %s", e.message);
        }
    }

    private async bool record_virtual () {
        ObjectPath path;
        try {
            path = yield session.record_virtual (new HashTable<string, Variant> (str_hash, str_equal));
        } catch (Error e) {
            warning ("Failed to record virtual: %s", e.message);
            return false;
        }

        return yield setup_mutter_stream (path, VIRTUAL);
    }

    private async void select_monitor () {
        var monitor_tracker = new MonitorTracker ();
        var monitor = monitor_tracker.monitors.get (0); //TODO
        record_monitor (monitor.connector);
    }

    private async bool record_monitor (string connector) {
        ObjectPath path;
        try {
            path = yield session.record_monitor (connector, new HashTable<string, Variant> (str_hash, str_equal));
        } catch (Error e) {
            warning ("Failed to record virtual: %s", e.message);
            return false;
        }

        return yield setup_mutter_stream (path, MONITOR);
    }

    private async bool setup_mutter_stream (ObjectPath proxy_path, SourceType source_type) {
        Mutter.ScreenCastStream mutter_stream;
        try {
            mutter_stream = yield Bus.get_proxy (SESSION, "org.gnome.Mutter.ScreenCast", proxy_path);
        } catch (Error e) {
            warning ("Failed to get mutter stream proxy: %s", e.message);
            return false;
        }

        mutter_stream.pipe_wire_stream_added.connect ((node_id) => {
            var properties = new HashTable<string, Variant> (str_hash, str_equal);
            properties["source_type"] = source_type;

            if ("size" in mutter_stream.parameters) {
                properties["size"] = mutter_stream.parameters["size"];
            }

            if ("position" in mutter_stream.parameters) {
                properties["position"] = mutter_stream.parameters["position"];
            }

            PipeWireStream stream = {
                node_id,
                properties
            };

            pipe_wire_stream_added (stream);
        });

        return true;
    }

    private void pipe_wire_stream_added (PipeWireStream pipe_wire_stream) {
        streams += pipe_wire_stream;
        if (streams.length == required_streams) {
            started (streams);
        }
    }

    public async void close () throws DBusError, IOError {
        warning ("Session closed");
        try {
            yield session.stop ();
        } catch (Error e) {
            warning ("Failed to close mutter ScreenCast session: %s", e.message);
        }

        closed (new HashTable<string, Variant> (str_hash, str_equal));
    }
}