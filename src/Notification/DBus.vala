[DBus (name = "io.elementary.portal.NotificationsProvider")]
public class Notification.Provider : Object {
    public signal void items_changed (uint pos, uint removed, HashTable<string, Variant>[] added);

    [DBus (visible = false)]
    public Portal portal { get; construct; }

    public Provider (Portal portal) {
        Object (portal: portal);
    }

    construct {
        portal.notifications.items_changed.connect (on_items_changed);
    }

    private void on_items_changed (uint pos, uint removed, uint added) {
        HashTable<string, Variant>[] added_notifications = new HashTable<string, Variant>[added];

        for (uint i = 0; i < added; i++) {
            added_notifications[i] = ((Notification) portal.notifications.get_item (pos + i)).data;
        }

        items_changed (pos, removed, added_notifications);
    }
}
