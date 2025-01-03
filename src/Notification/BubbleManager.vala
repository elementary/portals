

public class Notification.BubbleManager : Object {
    public Portal portal { get; construct; }

    public BubbleManager (Portal portal) {
        Object (portal: portal);
    }

    construct {
        portal.notifications.items_changed.connect (on_items_changed);
    }

    private void on_items_changed (uint pos, uint removed, uint added) {
        if (pos != 0 || removed != 0) {
            return;
        }

        var added_notification = (Notification) portal.notifications.get_item (pos);

        var bubble = new Bubble (portal, added_notification);
        bubble.present ();
    }
}
