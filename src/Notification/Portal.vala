// Copyright

// TEST CALL FOR DSPY:
// 'io.elementary.mail.desktop'
// 'new-mail'
// {'title': <'New mail from John Doe'>, 'body': <'You have a new mail from John Doe. Click to read it.'>, 'priority': <'high'>}

[DBus (name = "org.freedesktop.impl.portal.Notification")]
public class Notification.Portal : Object {
    private const string ID_FORMAT = "%s:%s";

    public signal void action_invoked (string app_id, string id, string action_name, Variant[] parameters);

    public HashTable<string, Variant> supported_options { get; construct; }
    public uint version { get; default = 2; }

    [DBus (visible = false)]
    public DBusConnection connection { private get; construct; }

    private FdoInterface fdo_interface;
    private HashTable<string, uint32> portal_id_to_fdo_id;

    public Portal (DBusConnection connection) {
        Object (connection: connection);
    }

    construct {
        supported_options = new HashTable<string, Variant> (str_hash, str_equal);
        portal_id_to_fdo_id = new HashTable<string, uint32> (str_hash, str_equal);

        try {
            fdo_interface = Bus.get_proxy_sync (SESSION, "org.freedesktop.Notifications", "/org/freedesktop/Notifications");
        } catch (Error e) {
            critical (e.message);
        }
    }

    public void add_notification (string app_id, string id, HashTable<string, Variant> data) throws Error {
        if (!("title" in data)) {
            throw new DBusError.FAILED ("Can't show notification without title");
        }

        unowned var title = data["title"].get_string ();

        unowned string body = "";
        if ("body-markup" in data) {
            body = data["body-markup"].get_string ();
        } else if ("body" in data) {
            body = data["body"].get_string ();
        }

        uint8 priority = 1;
        if ("priority" in data) {
            switch (data["priority"].get_string ()) {
                case "low":
                    priority = 0;
                    break;

                case "normal":
                    priority = 1;
                    break;
                case "high":
                    priority = 2;
                    break;
                case "urgent":
                    priority = 2;
                    break;
            }
        }

        var hints = new HashTable<string, Variant> (str_hash, str_equal);
        hints["urgency"] = priority;

        try {
            var fdo_id = fdo_interface.notify (app_id, 0, app_id, title, body, {}, hints, 0);
            portal_id_to_fdo_id[ID_FORMAT.printf (app_id, id)] = fdo_id;
        } catch (Error e) {
            critical (e.message);
            throw new DBusError.FAILED ("Failed to send notification: %s", e.message);
        }
    }

    public void remove_notification (string app_id, string id) throws Error {
        var formatted_id = ID_FORMAT.printf (app_id, id);

        if (!(formatted_id in portal_id_to_fdo_id)) {
            throw new DBusError.FAILED ("Provided id %s not found", id);
        }

        try {
            fdo_interface.close_notification (portal_id_to_fdo_id[formatted_id]);
        } catch (Error e) {
            critical (e.message);
            throw new DBusError.FAILED ("Failed to close notification: %s", e.message);
        }
    }
}
