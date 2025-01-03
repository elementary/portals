// TEST CALL FOR DSPY:

// ('io.elementary.mail.desktop', 'new-mail', {'title': <'New mail from John Doe'>, 'body': <'You have a new mail from John Doe. Click to read it.'>})

/**
 * The portal.
 * On receiving:
 * - check if already there
 */
[DBus (name = "org.freedesktop.impl.portal.Notification")]
public class Notification.Portal : Object {
    public const string ID_FORMAT = "%s:%s";
    public const string ACTION_FORMAT = "%s+action+%s"; // interal id, action id
    public const string INTERNAL_ACTION_FORMAT = "%s+internal+%s"; // interal id, action id

    public signal void action_invoked (string app_id, string id, string action_name, Variant[] parameters);

    public HashTable<string, Variant> supported_options { get; construct; }

    [DBus (visible = false)]
    public ListStore notifications { get; construct; }
    [DBus (visible = false)]
    public ActionGroup actions { get; construct; }

    construct {
        supported_options = new HashTable<string, Variant> (str_hash, str_equal);

        notifications = new ListStore (typeof (Notification));
        actions = new ActionGroup (this);
    }

    public void add_notification (string app_id, string id, HashTable<string, Variant> data) throws DBusError, IOError {
        var internal_id = ID_FORMAT.printf (app_id, id);
        var notification = new Notification (app_id, id, data);

        replace_notification (internal_id, notification);
    }

    public void remove_notification (string app_id, string id) throws DBusError, IOError {
        var internal_id = ID_FORMAT.printf (app_id, id);

        replace_notification (internal_id, null);
    }

    /**
     * Removes the given id and if not null replaces it with the given notification at the same position.
     * If SHOW_AS_NEW is set in the display hint of the replacement, it will be added at the front instead of at the same position.
     * If no notification with the given id is found, and the replacement is not null, the replacement will be added at the front.
     */
    internal void replace_notification (string internal_id, Notification? replacement) {
        for (int i = 0; i < notifications.n_items; i++) {
            var notification = (Notification) notifications.get_object (i);
            if (notification.id == internal_id) {
                if (replacement == null) { // Just remove and return
                    notifications.remove (i);
                    return;
                } else if (SHOW_AS_NEW in replacement.display_hint) { // Remove but don't return because we want to add the replacement as if it was a new notification
                    notifications.remove (i);
                } else { // Replace and return
                    notifications.splice (i, 1, { replacement });
                    return;
                }
            }
        }

        notifications.append (replacement);
    }
}
