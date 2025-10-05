// Copyright

[DBus (name = "org.freedesktop.impl.portal.Notification")]
public class Notification.Portal : Object {
    [DBus (name = "io.elementary.notifications.PortalProxy")]
    private interface PortalProxy : Object {
        public abstract HashTable<string, Variant> supported_options { owned get; }
        public abstract uint version { owned get; }

        public signal void action_invoked (string app_id, string id, string action_name, Variant[] action_parameters);

        public abstract void add_notification (string app_id, string id, HashTable<string, Variant> data) throws Error;
        public abstract void remove_notification (string app_id, string id) throws Error;
    }

    public signal void action_invoked (string app_id, string id, string action_name, Variant[] parameters);

    public HashTable<string, Variant> supported_options {
        owned get {
            return proxy.supported_options;
        }
    }

    public uint version {
        get {
            return proxy.version;
        }
    }

    private PortalProxy proxy; 

    construct {
        try {
            proxy = Bus.get_proxy_sync<PortalProxy> (
                SESSION, "io.elementary.notifications.PortalProxy", "/io/elementary/notifications/PortalProxy"
            );
            proxy.action_invoked.connect (
                (app_id, id, action, parameters) => action_invoked (app_id, id, action, parameters)
            );
        } catch (Error e) {
            critical ("Couldn't connect to notifications portal proxy: %s", e.message);
        }
    }

    public void add_notification (string app_id, string id, HashTable<string, Variant> data) throws Error {
        proxy.add_notification (app_id, id, data);
    }

    public void remove_notification (string app_id, string id) throws Error {
        proxy.remove_notification (app_id, id);
    }
}