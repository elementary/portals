[DBus (name = "io.elementary.portal.NotificationProvider")]
public class Notification.DBusProvider : Object {
    public signal void items_changed (uint pos, uint removed, uint added);

    [DBus (visible = false)]
    public Portal portal { get; construct; }

    public DBusProvider (Portal portal) {
        Object (portal: portal);
    }

    construct {
        portal.notifications.items_changed.connect ((pos, removed, added) => items_changed (pos, removed, added));
    }

    public uint get_n_items () throws DBusError, IOError {
        return portal.notifications.n_items;
    }

    public Notification.Data get_notification (uint index) throws DBusError, IOError {
        return ((Notification) portal.notifications.get_item (index)).data;
    }
}
