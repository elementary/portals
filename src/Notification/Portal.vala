// TEST CALL FOR DSPY:

// ('io.elementary.mail.desktop', 'new-mail', {'title': <'New mail from John Doe'>, 'body': <'You have a new mail from John Doe. Click to read it.'>})


[DBus (name = "org.freedesktop.impl.portal.Notification")]
public class Notification.Portal : Object {
    public const string ID_FORMAT = "%s:%s";

    public signal void action_invoked (string app_id, string id, string action_name, Variant[] parameters);

    public HashTable<string, Variant> supported_options { get; construct; }

    [DBus (visible = false)]
    public ListStore notifications { get; construct; }

    private HashTable<string, PortalNotification> notifications_by_id;

    private Gtk.Window? main_window;

    construct {
        notifications = new ListStore (typeof (PortalNotification));
        notifications_by_id = new HashTable<string, PortalNotification> (str_hash, str_equal);
        supported_options = new HashTable<string, Variant> (str_hash, str_equal);
    }

    public void add_notification (string app_id, string id, HashTable<string, Variant> data) throws DBusError, IOError {
        var internal_id = ID_FORMAT.printf (app_id, id);

        var notification = new PortalNotification (app_id, id, data);

        if (internal_id in notifications_by_id) {
            if (SHOW_AS_NEW in notification.display_hint) {
                remove_notification (app_id, id);
            } else {
                notifications_by_id[internal_id].replace (data);
                return;
            }
        }

        notification.dismissed.connect (remove_notification_internal);
        notification.activate_action.connect ((name, target) => action_invoked (app_id, id, name, {target}));
        notifications_by_id[internal_id] = notification;
        notifications.append (notification);

        if (main_window == null) {
            main_window = new MainWindow (this);
        }

        Idle.add_once (() => main_window.present ());
    }

    public void remove_notification (string app_id, string id) throws DBusError, IOError {
        var internal_id = ID_FORMAT.printf (app_id, id);

        remove_notification_internal (internal_id);
    }

    private void remove_notification_internal (string internal_id) {
        notifications_by_id.remove (internal_id);

        for (int i = 0; i < notifications.n_items; i++) {
            var notification = (PortalNotification) notifications.get_object (i);
            if (notification.id == internal_id) {
                notifications.remove (i);
                break;
            }
        }
    }
}
