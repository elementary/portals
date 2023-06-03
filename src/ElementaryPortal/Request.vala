[DBus (name = "org.freedesktop.portal.Request")]
public class EvolutionCredentials.Request : Object {
    public signal void response (uint response, HashTable<string, Variant> results);

    [DBus (visible = false)]
    public signal void closed ();

    public void close () throws DBusError, IOError {
        closed ();
    }
}
