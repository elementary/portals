public class NotificationHandler : Object {
    public const string ACTION_ALLOW_BACKGROUND = "background.allow";
    public const string ACTION_FORBID_BACKGROUND = "background.forbid";

    private DBusConnection connection;
    private HashTable<uint32, NotificationRequest> notification_by_id;
    private Notifications notifications;

    private enum NotifyBackgroundResult {
        FORBID,
        ALLOW,
        ALLOW_ONCE
    }

    [DBus (name = "org.freedesktop.Notifications")]
    public interface Notifications : Object {
        public signal void action_invoked (uint32 id, string action_key);
        public signal void notification_closed (uint32 id, uint32 reason);

        public abstract void close_notification (uint32 id) throws DBusError, IOError;
        public abstract uint32 notify (
            string app_name,
            uint32 replaces_id,
            string app_icon,
            string summary,
            string body,
            string[] actions,
            HashTable<string, Variant> hints,
            int32 expire_timeout
        ) throws DBusError, IOError;
    }

    public NotificationHandler (DBusConnection connection) {
        this.connection = connection;
        notification_by_id = new HashTable<uint32, NotificationRequest> (null, null);

        try {
            notifications = connection.get_proxy_sync ("org.freedesktop.Notifications", "/org/freedesktop/Notifications");
            notifications.action_invoked.connect (on_action_invoked);
            notifications.notification_closed.connect (on_notification_closed);
        } catch {
            warning ("Cannot connect to notifications dbus, background portal working with reduced functionality.");
        }
    }

    public NotificationRequest? send_notification (string app_id, string app_name) {
        string[] actions = {
            ACTION_ALLOW_BACKGROUND,
            _("Allow"),
            ACTION_FORBID_BACKGROUND,
            _("Forbid")
        };

        try {
            var id = notifications.notify (
                Environment.get_prgname (),
                0,
                "dialog-information",
                _("Background activity"),
                _(""""%s" is running in the background""").printf (app_name),
                actions,
                new HashTable<string, Variant> (str_hash, str_equal),
                0
            );

            var notification = new NotificationRequest (this, id);
            notification_by_id.set (id, notification);

            return notification;
        } catch (Error e) {
            warning ("Failed to send notification for app id '%s': %s", app_id, e.message);
            return null;
        }
    }

    private void on_action_invoked (uint32 id, string action_key) {
        if (id in notification_by_id) {
            var notification = notification_by_id.get (id);
            if (action_key == NotificationHandler.ACTION_ALLOW_BACKGROUND) {
                notification.response (NotifyBackgroundResult.ALLOW);
            } else if (action_key == NotificationHandler.ACTION_FORBID_BACKGROUND) {
                notification.response (NotifyBackgroundResult.FORBID);
            }

            notification_by_id.remove (id);
        }
    }

    private void on_notification_closed (uint32 id, uint32 reason) {
        if (id in notification_by_id) {
            var notification = notification_by_id.get (id);
            if (reason == 2 || reason == 3) {
                notification.response (NotifyBackgroundResult.ALLOW_ONCE);

                notification_by_id.remove (id);
            }
        }
    }

    public void close_notification (uint32 id) {
        try {
            notifications.close_notification (id);
        } catch (Error e) {
            warning ("Failed to close notification with id '%u': %s", id, e.message);
        }

        notification_by_id.remove (id);
    }
}
