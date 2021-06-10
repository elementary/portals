/*
 *
 *
 */

[DBus (name = "org.freedesktop.impl.portal.Access")]
public class Access.Portal : Object {
    private DBusConnection connection;

    public Portal (DBusConnection connection) {
        this.connection = connection;
    }

    public async void access_dialog (
        ObjectPath handle,
        string app_id,
        string parent_window,
        string title,
        string sub_title,
        string body,
        HashTable<string, Variant> options,
        out uint32 response,
        out HashTable<string, Variant> results
    ) throws DBusError, IOError {

        var dialog = new Dialog (
            connection,
            handle,
            app_id,
            parent_window,
            title,
            sub_title,
            body
        );

        if ("modal" in options && options["modal"].is_of_type (VariantType.BOOLEAN)) {
            dialog.modal = options["modal"].get_boolean ();
        } if ("deny_label" in options && options["deny_label"].is_of_type (VariantType.STRING)) {
            dialog.deny_label = options["deny_label"].get_string ();
        } if ("grant_label" in options && options["grant_label"].is_of_type (VariantType.STRING)) {
            dialog.grant_label = options["grant_label"].get_string ();
        } if ("icon" in options && options["icon"].is_of_type (VariantType.STRING)) {
            // elementary HIG use non-symbolic icon, while portals ask for symbolic ones.
            dialog.image_icon = new ThemedIcon (options["icon"].get_string ().replace ("-symbolic", ""));
        }

        if ("choices" in options && options["choices"].is_of_type (new VariantType ("a(ssa(ss)s)"))) {
            var choices = options["choices"];

            for (size_t i = 0; i < choices.n_children (); ++i) {
                dialog.add_choice (choices.get_child_value (i));
            }
        }

        var _results = new HashTable<string, Variant> (str_hash, str_equal);
        uint _response = 2;

        dialog.response.connect ((id) => {
            switch ((Gtk.ResponseType) id) {
                case Gtk.ResponseType.OK:
                    _response = 0;
                    _results["choices"] = dialog.choices;
                    break;
                case Gtk.ResponseType.CANCEL:
                    _response = 1;
                    break;
                case Gtk.ResponseType.DELETE_EVENT:
                    _response = 2;
                    break;
            }

            access_dialog.callback ();
        });

        dialog.show_all ();
        yield;
        results = _results;
        response = _response;
    }
}
