/*
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.Notifications")]
private interface Fdo.Notifications : Object {
    public signal void action_invoked (uint32 id, string action_key);
    public signal void notification_closed (uint32 id, CloseReason reason);

    public const string NAME = "org.freedesktop.Notifications";
    public const string PATH = "/org/freedesktop/Notifications";

    [CCode (type_signature = "u")]
    public enum CloseReason {
        EXPIRED = 1,
        DIMISSED,
        CANCELLED
    }

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

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class Background.NotificationRequest : Object {
    [DBus (visible = false)]
    public signal void response (NotifyBackgroundResult result);

    private const string ACTION_ALLOW_BACKGROUND = "background.allow";
    private const string ACTION_FORBID_BACKGROUND = "background.forbid";

    private static HashTable<uint32, unowned NotificationRequest> requests;
    private static Fdo.Notifications notifications;

    private uint32 id = 0;

    [CCode (type_signature = "u")]
    public enum NotifyBackgroundResult {
        FORBID,
        ALLOW,
        ALLOW_ONCE,
        CANCELLED,
        FAILED
    }

    public static void init (DBusConnection connection) {
        requests = new HashTable<uint32, unowned NotificationRequest> (null, null);

        try {
            notifications = connection.get_proxy_sync (Fdo.Notifications.NAME, Fdo.Notifications.PATH);
            notifications.action_invoked.connect (action_invoked);
            notifications.notification_closed.connect (notification_closed);
        } catch {
            warning ("Cannot connect to notifications dbus, portal working with reduced functionality.");
        }
    }

    private static void action_invoked (uint32 id, string action_key) {
        unowned var notification = requests.take (id);
        if (notification == null) {
            return;
        }

        if (action_key == ACTION_ALLOW_BACKGROUND) {
            notification.response (ALLOW);
        } else {
            notification.response (FORBID);
        }
    }

    private static void notification_closed (uint32 id, Fdo.Notifications.CloseReason reason) {
        unowned var notification = requests.take (id);
        if (notification == null) {
            return;
        }

        if (reason == CANCELLED) { // Closed via DBus call
            notification.response (CANCELLED);
        } else { // Dismissed, Expired, or something internal to the server
            notification.response (ALLOW_ONCE);
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
                _("“%s” is running in the background without appropriate permission").printf (app_name),
                actions,
                hints,
                -1
            );

            requests[id] = this;
        } catch (Error e) {
            warning ("Failed to notify background activity from '%s': %s", app_id, e.message);
            response (FAILED);
        }
    }

    public void close () throws DBusError, IOError {
        try {
            notifications.close_notification (id);
        } catch (Error e) {
            // the notification was already closed, or we lost the connection to the server
        }
    }
}
