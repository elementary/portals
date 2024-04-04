
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

    public uint version { get; default = 1; }

    private Mutter.ScreenCastSession session;

    private SourceType source_types;
    private bool allow_multiple;

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

    internal async Variant? start () {
        //do selection, etc.
        //we want virtual

        ObjectPath path;
        try {
            path = yield session.record_virtual (new HashTable<string, Variant> (str_hash, str_equal));
        } catch (Error e) {
            warning ("Failed to record virtual: %s", e.message);
            return null;
        }

        Mutter.ScreenCastStream mutter_stream;
        try {
            mutter_stream = yield Bus.get_proxy (SESSION, "org.gnome.Mutter.ScreenCast", path);
        } catch (Error e) {
            warning ("Failed to get mutter stream proxy: %s", e.message);
            return null;
        }

        PipeWireStream[] streams = {};
        mutter_stream.pipe_wire_stream_added.connect ((node_id) => {
            var properties_builder = new VariantBuilder (VariantType.VARDICT);
            properties_builder.add ("{sv}", "position", new Variant (("(ii)"), 0, 0));
            properties_builder.add ("{sv}", "size", new Variant (("(ii)"), 1980, 1080));
            properties_builder.add ("{sv}", "source_type", new Variant ("u", 4));
            var properties = properties_builder.end ();

            PipeWireStream stream = {
                node_id,
                (HashTable<string, Variant>) properties
            };

            streams += stream;

            start.callback ();
        });

        try {
            yield session.start ();
            yield;
        } catch (Error e) {
            warning ("Failed to start mutter session: %s", e.message);
            return null;
        }

        return streams;
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