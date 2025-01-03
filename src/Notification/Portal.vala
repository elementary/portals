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
    public SimpleActionGroup actions { get; construct; }

    construct {
        supported_options = new HashTable<string, Variant> (str_hash, str_equal);

        notifications = new ListStore (typeof (Notification));
        actions = new SimpleActionGroup ();
    }

    public void add_notification (string app_id, string id, HashTable<string, Variant> data) throws DBusError, IOError {
        var internal_id = ID_FORMAT.printf (app_id, id);
        var notification = new Notification (app_id, id, data, this);

        replace_notification_internal (internal_id, notification);
    }

    public void remove_notification (string app_id, string id) throws DBusError, IOError {
        var internal_id = ID_FORMAT.printf (app_id, id);

        replace_notification_internal (internal_id, null);
    }

    /**
     * Removes the given id and if not null replaces it with the given notification at the same position.
     * If SHOW_AS_NEW is set in the display hint of the replacement, it will be added at the front instead of at the same position.
     * If no notification with the given id is found, and the replacement is not null, the replacement will be added at the front.
     */
    private void replace_notification_internal (string internal_id, Notification? replacement) {
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

    internal void on_action (SimpleAction action, Variant? parameter) {
        var name = action.name;

        var parts = name.split ("+", 3);

        if (parts.length != 3) {
            warning ("Invalid action name: %s", name);
            return;
        }

        var internal_id = parts[0];
        var type = parts[1];
        var action_name = parts[2];

        var id_parts = internal_id.split (":", 2);

        if (id_parts.length != 2) {
            warning ("Invalid internal id: %s", internal_id);
            return;
        }

        var app_id = id_parts[0];
        var notification_id = id_parts[1];

        if (type == "action") {
            action_invoked (app_id, notification_id, action_name, { parameter });
        } else {
            switch (action_name) {
                case "default":
                    // launch
                    break;

                case "dismiss":
                    replace_notification_internal (internal_id, null);
                    break;

                default:
                    break;
            }
        }
    }
}
