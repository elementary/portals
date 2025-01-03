public class Notification.Bubble : Gtk.Window {
    public Portal portal { get; construct; }
    public Notification notification { get; construct; }

    public Bubble (Portal portal, Notification notification) {
        Object (portal: portal, notification: notification);
    }

    construct {
        child = new Widget (notification);

        insert_action_group (Notification.ACTION_GROUP_NAME, portal.actions);
    }
}
