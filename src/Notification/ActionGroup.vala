
/**
 * Handles all action logic for notifications. It automatically tracks currently available notifications
 * and lists their available actions. On activation it will emit the action_invoked signal on the portal, or
 * close the notification or launch the application.
 */
public class Notification.ActionGroup : Object, GLib.ActionGroup {
    private const string TARGET_TYPE_STRING = "(sv)";
    public static VariantType target_type = new VariantType (TARGET_TYPE_STRING);

    public Portal portal { get; construct; }

    public ActionGroup (Portal portal) {
        Object (portal: portal);
    }

    construct {
        portal.notifications.items_changed.connect (on_items_changed);
    }

    private void on_items_changed (uint pos, uint removed, uint added) {
        for (uint i = pos; i < pos + added; i++) {
            var notification = (Notification) portal.notifications.get_item (i);

            foreach (var action in notification.list_actions ()) {
                action_added (action);
            }
        }

        //TODO: Maybe handle remove
    }

    public string[] list_actions () {
        var builder = new StrvBuilder ();

        for (uint i = 0; i < portal.notifications.n_items; i++) {
            var notification = (Notification) portal.notifications.get_item (i);
            builder.addv (notification.list_actions ());
        }

        return builder.end ();
    }

    public void activate_action (string name, Variant? target) {
        if (target == null || !target.is_of_type (target_type)) {
            warning ("Invalid action target for action %s", name);
            return;
        }

        var parts = name.split ("+", 3);

        if (parts.length != 3) {
            warning ("Invalid action name: %s", name);
            return;
        }

        var internal_id = parts[0];
        var type = parts[1];
        var action_name = parts[2];

        var notification = Notification.get_for_internal_id (internal_id);

        if (notification == null) {
            warning ("Notification not found: %s", internal_id);
            return;
        }

        var app_id = notification.app_id;
        var id = notification.id;

        switch (type) {
            case Notification.ACTION_TYPE_ACTION:
                string activation_token;
                Variant action_target;
                target.get ("(sv)", out activation_token, out action_target);

                Variant[] action_target_array;
                action_target.get ("av", out action_target_array);

                var platform_data = new HashTable<string, Variant> (str_hash, str_equal);
                platform_data["activation-token"] = activation_token;

                var parameters = new Gee.LinkedList<Variant> ();

                parameters.add_all_array (action_target_array);
                parameters.add (platform_data);

                portal.action_invoked (app_id, id, action_name, parameters.to_array ());
                break;

            case Notification.ACTION_TYPE_INTERNAL:
                switch (action_name) {
                    case Notification.ACTION_DEFAULT:
                        // launch
                        warning ("Launched");
                        break;

                    case Notification.ACTION_DISMISS:
                        break;

                    default:
                        return;
                }
                break;

            default:
                return;
        }

        uint position;
        if (portal.notifications.find (notification, out position)) {
            portal.notifications.remove (position);
        }
    }

    public override bool query_action (
        string name,
        out bool enabled,
        out unowned VariantType parameter_type,
        out unowned VariantType state_type,
        out Variant state_hint,
        out Variant state
    ) {
        enabled = true;
        parameter_type = null;
        state_type = null;
        state_hint = null;
        state = null;

        var parts = name.split ("+", 3);

        if (parts.length != 3) {
            warning ("Invalid action name: %s", name);
            return false;
        }

        var notification = Notification.get_for_internal_id (parts[0]);

        if (notification == null) {
            warning ("Notification not found: %s", parts[0]);
            return false;
        }

        return notification.query_action (name, out enabled, out parameter_type, out state_type, out state_hint, out state);
    }

    public void change_action_state (string action_name, Variant value) { }
}
