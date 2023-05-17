[DBus (name = "org.freedesktop.impl.portal.Request")]
public class NotificationRequest : Object {
    [DBus (visible = false)]
    public signal void response (uint32 result);

    public uint register_id { get; set; default = 0; }

    private NotificationHandler handler;
    private uint32 id;

    public NotificationRequest (NotificationHandler handler, uint32 id) {
        this.handler = handler;
        this.id = id;
    }

    public void close () throws DBusError, IOError {
        handler.close_notification (id);
    }
}
