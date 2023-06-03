public class ElementaryPortal : Object {
    uint owner_id;

    construct {
        owner_id = GLib.Bus.own_name (
            GLib.BusType.SESSION,
            "org.freedesktop.portal.elementary",
            GLib.BusNameOwnerFlags.ALLOW_REPLACEMENT | (opt_replace ? GLib.BusNameOwnerFlags.REPLACE : 0),
            on_bus_acquired
        );
    }

    ~ElementaryPortal () {
        GLib.Bus.unown_name (owner_id);
    }

    private void on_bus_acquired (DBusConnection connection, string name) {
        PermissionStore.init (connection);

        try {
            connection.register_object ("/org/freedesktop/portal/elementary", new EvolutionCredentials.Portal (connection));
            debug ("EvolutionCredentials Portal registered!");
        } catch (Error e) {
            critical ("Unable to register the object: %s", e.message);
        }
    }
}
