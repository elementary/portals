/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class NotificationRequest : Object {
    [DBus (visible = false)]
    public signal void response (uint32 result);

    private const string ACTION_ALLOW_BACKGROUND = "background.allow";
    private const string ACTION_FORBID_BACKGROUND = "background.forbid";

    private static HashTable<uint32, NotificationRequest> notification_by_id;
    private static Notifications notifications;

    private uint32 id = 0;

    public enum NotifyBackgroundResult {
        FORBID,
        ALLOW,
        ALLOW_ONCE,
        CANCELLED
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

    [DBus (visible = false)]
    public static void init (DBusConnection connection) {
        notification_by_id = new HashTable<uint32, NotificationRequest> (null, null);

        try {
            notifications = connection.get_proxy_sync ("org.freedesktop.Notifications", "/org/freedesktop/Notifications");
            notifications.action_invoked.connect (on_action_invoked);
            notifications.notification_closed.connect (on_notification_closed);
        } catch {
            warning ("Cannot connect to notifications dbus, background portal working with reduced functionality.");
        }
    }

    private static void on_action_invoked (uint32 id, string action_key) {
        var notification = notification_by_id.take (id);
        if (notification == null) {
            return;
        }

        if (action_key == ACTION_ALLOW_BACKGROUND) {
            notification.response (NotifyBackgroundResult.ALLOW);
        } else if (action_key == ACTION_FORBID_BACKGROUND) {
            notification.response (NotifyBackgroundResult.FORBID);
        }
    }

    private static void on_notification_closed (uint32 id, uint32 reason) {
        var notification = notification_by_id.take (id);
        if (notification == null) {
            return;
        }

        if (reason == 2) { //Dismissed by user
            notification.response (NotifyBackgroundResult.ALLOW_ONCE);
        } else if (reason == 3) { //Closed via DBus call
            notification.response (NotifyBackgroundResult.CANCELLED);
        }
    }

    [DBus (visible = false)]
    public void send_notification (string app_id, string app_name) {
        string[] actions = {
            ACTION_ALLOW_BACKGROUND,
            _("Allow"),
            ACTION_FORBID_BACKGROUND,
            _("Forbid")
        };
        var hints = new HashTable<string, Variant> (null, null);
        hints["desktop-entry"] = app_id;
        hints["urgency"] = (uint8) 1;

        try {
            id = notifications.notify (
                app_name, 0, "",
                _("Background activity"),
                _(""""%s" is running in the background""").printf (app_name),
                actions,
                hints,
                0
            );

            notification_by_id.set (id, this);
        } catch (Error e) {
            warning ("Failed to send notification for app id '%s': %s", app_id, e.message);
            response (NotifyBackgroundResult.ALLOW_ONCE);
        }
    }

    public void close () throws DBusError, IOError {
        try {
            notifications.close_notification (id);
        } catch (Error e) {
            // the notification was already closed, or we lost the connection to the server
            response (NotifyBackgroundResult.CANCELLED);
            notification_by_id.remove (id);
        }
    }
}
