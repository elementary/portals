// TEST CALL FOR DSPY:

// ('io.elementary.mail.desktop', 'new-mail', {'title': <'New mail from John Doe'>, 'body': <'You have a new mail from John Doe. Click to read it.'>})

/**
 * The notififcations portal consists of a few parts. Most importantly this class which exposes the portal
 * api, tracks currently active notifications and holds the other parts.
 * The {@link ActionGroup} handles all action logic for notifications. It automatically exposes all actions
 * for all available notifications and handles the activation of these actions (by talking to #this).
 * It's also exported on the bus for usage by the indicator.
 * The {@link BubbleManager} is responsible for showing the notifications to the user in a bubble.
 * The {@link DBusProvider} is responsible for exposing the notifications to the DBus for consumption by the indicator.
 * Both {@link BubbleManager} and {@link DBusProvider} use the {@link actions} for all interaction (dismissing, activating actions).
 */
[DBus (name = "org.freedesktop.impl.portal.Notification")]
public class Notification.Portal : Object {
    public const string ID_FORMAT = "%s:%s";

    public signal void action_invoked (string app_id, string id, string action_name, Variant[] parameters);

    public HashTable<string, Variant> supported_options { get; construct; }
    public uint version { get; default = 2; }

    [DBus (visible = false)]
    public DBusConnection connection { private get; construct; }

    [DBus (visible = false)]
    public ListStore notifications { get; construct; }

    private ActionGroup actions;
    private DBusProvider dbus_provider;

    public Portal (DBusConnection connection) {
        Object (connection: connection);
    }

    construct {
        supported_options = new HashTable<string, Variant> (str_hash, str_equal);

        notifications = new ListStore (typeof (Notification));
        actions = new ActionGroup (this);

        dbus_provider = new DBusProvider (this);

        try {
            connection.register_object ("/io/elementary/portal/NotificationProvider", dbus_provider);
            connection.export_action_group ("/io/elementary/portal/NotificationProvider", actions);
        } catch (Error e) {
            warning ("Failed to register provider: %s", e.message);
        }
    }

    public void add_notification (string app_id, string id, HashTable<string, Variant> data) throws DBusError, IOError {
        var notification = new Notification (app_id, id, data);
        replace_notification (app_id, id, notification);
    }

    public void remove_notification (string app_id, string id) throws DBusError, IOError {
        replace_notification (app_id, id, null);
    }

    /**
     * Removes the given id and if not null replaces it with the given notification at the same position.
     * If SHOW_AS_NEW is set in the display hint of the replacement, it will be added at the front instead of at the same position.
     * If no notification with the given id is found, and the replacement is not null, the replacement will be added at the front.
     */
    internal void replace_notification (string app_id, string id, Notification? replacement) {
        if (id != "") {
            for (uint i = 0; i < notifications.n_items; i++) {
                var notification = (Notification) notifications.get_item (i);
                if (notification.app_id != app_id || notification.id != id) {
                    continue;
                }

                if (replacement == null) { // Just remove and return
                    notifications.remove (i);
                    return;
                } else if (SHOW_AS_NEW in replacement.display_hint) { // Remove but don't return because we want to add the replacement as if it was a new notification
                    notifications.remove (i);
                    break;
                } else { // Replace and return
                    replacement.replace_timestamp (notification);
                    notifications.splice (i, 1, { replacement });
                    return;
                }
            }
        }

        if (replacement != null) {
            notifications.splice (0, 0, { replacement });
        } else {
            warning ("This shouldn't be reached.");
        }
    }
}
