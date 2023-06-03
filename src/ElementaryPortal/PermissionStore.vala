
    [DBus (name = "org.freedesktop.impl.portal.PermissionStore")]
    public interface PermissionStore : Object {
        public static PermissionStore permission_store;
        public static void init (DBusConnection connection) {
            try {
                permission_store = connection.get_proxy_sync ("org.freedesktop.impl.portal.PermissionStore", "/org/freedesktop/impl/portal/PermissionStore");
            } catch {
                critical ("Cannot connect to PermissionStore dbus, elementary portal working with reduced functionality.");
            }
        }

        public static void set_permission (string table, bool create, string id, string app_id, string[] permissions) throws DBusError, IOError {
            permission_store._set_permission (table, create, id, app_id, permissions);
        }

        public static string[]? get_permission (string table, string id, string app_id) throws DBusError, IOError{
            return permission_store._get_permission (table, id, app_id);
        }

        [DBus (name = "SetPermission")]
        public abstract void _set_permission (string table, bool create, string id, string app_id, string[] permissions) throws DBusError, IOError;
        [DBus (name = "GetPermission")]
        public abstract string[]? _get_permission (string table, string id, string app_id) throws DBusError, IOError;
    }

