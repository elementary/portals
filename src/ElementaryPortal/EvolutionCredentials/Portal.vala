[DBus (name = "org.freedesktop.portal.elementary.EvolutionCredentials")]
public class EvolutionCredentials.Portal : Object {
    private const string TABLE = "evolution-credentials";
    private const string ID = "evolution-credentials";

    private const string PERMISSION_ALLOW = "allow";
    private const string PERMISSION_FORBID = "forbid";
    private const string PERMISSION_ASK = "ask";

    private DBusConnection connection;
    private E.SourceRegistry registry;

    public Portal (DBusConnection connection) {
        this.connection = connection;
        get_registry.begin ();
    }

    private async void get_registry () {
        try {
            registry = yield new E.SourceRegistry (null);
        } catch (Error e) {
            critical ("EvolutionCredentials Portal not functional: Failed to get Evolution SourceRegistry: %s", e.message);
        }
    }

    public async void get_credentials_for_account_uid (
        string app_id,
        string parent_window,
        string account_uid,
        string handle_token
    ) throws DBusError, IOError {
        uint response = 2;
        var request = new Request ();
        var results = new HashTable<string, Variant> (str_hash, str_equal);

        uint register_id;

        try {
            register_id = connection.register_object ("/org/freedesktop/portal/elementary/%s/%s".printf (app_id, handle_token), request);
        } catch (Error e) {
            warning ("Failed to register request object: %s", e.message);
            throw new DBusError.OBJECT_PATH_IN_USE (e.message);
        }

        try {
            var permissions = PermissionStore.get_permission (TABLE, ID, app_id);
            switch (permissions[0]) {
                case PERMISSION_ALLOW:
                    response = 0;
                    break;
                case PERMISSION_FORBID:
                    response = 1;
                    break;
                default:
                    break;
            }
        } catch (Error e) {
            warning ("Failed to get permission: %s", e.message);
        }

        if (response == 2) {
            var dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Allow %s to access your Online Accounts?"),
                _("This is a valid reason"),
                "dialog-warning",
                Gtk.ButtonsType.NONE
            );
            dialog.add_button (_("Forbid"), 1);
            var allow_button = dialog.add_button (_("Allow"), 0);
            allow_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

            dialog.response.connect ((_response) => {
                string permission;

                switch (_response) {
                    case 0:
                        response = 0;
                        permission = PERMISSION_ALLOW;
                        break;
                    case 1:
                        response = 1;
                        permission = PERMISSION_FORBID;
                        break;
                    default:
                        permission = PERMISSION_ASK;
                        break;
                }

                try {
                    PermissionStore.set_permission (TABLE, true, ID, app_id, { permission });
                } catch (Error e) {
                    warning ("Failed to set permission for '%s': %s", app_id, e.message);
                }

                dialog.destroy ();
                get_credentials_for_account_uid.callback ();
            });

            request.closed.connect (() => {
                dialog.destroy ();
                get_credentials_for_account_uid.callback ();
            });

            dialog.present ();

            yield;
        }

        if (response == 0) {
            try {
                var credentials = yield lookup_credentials (account_uid);
                results["credentials"] = credentials;
            } catch (Error e) {
                warning ("Credentials for account uid '%s' not found: %s", account_uid, e.message);
                response = 2;
            }
        }

        request.response (response, results);
        connection.unregister_object (register_id);
    }

    private async string lookup_credentials (string account_uid) throws Error {
        string? password;

        var source = registry.ref_source (account_uid);
        if (!yield source.lookup_password (null, out password)) {
            throw new IOError.NOT_FOUND ("Password not found");
        }

        return password;
    }

}
