
/**
 * Handles all action logic for notifications. It automatically tracks currently available notifications
 * and lists their available actions. On activation it will emit the action_invoked signal on the portal, or
 * close the notification or launch the application.
 */
public class Notification.ActionGroup : Object, GLib.ActionGroup {
    public Portal portal { get; construct; }

    public ActionGroup (Portal portal) {
        Object (portal: portal);
    }

    public string[] list_actions () {
        var builder = new StrvBuilder ();

        for (uint i = 0; i < portal.notifications.n_items; i++) {
            var notification = (Notification) portal.notifications.get_item (i);

            builder.add (notification.dismiss_action_name);
            builder.add (notification.default_action_name);

            foreach (var button in notification.buttons) {
                builder.add (button.action_name);
            }
        }

        return builder.end ();
    }

    public void activate_action (string name, Variant? target) {
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
            portal.action_invoked (app_id, notification_id, action_name, { target });
        } else {
            switch (action_name) {
                case "default":
                    // launch
                    break;

                case "dismiss":
                    portal.replace_notification (internal_id, null);
                    break;

                default:
                    break;
            }
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

        var internal_id = parts[0];
        var type = parts[1];
        var action_name = parts[2];

        Notification? notification = null;
        for (uint i = 0; i < portal.notifications.n_items; i++) {
            var n = (Notification) portal.notifications.get_item (i);
            if (n.internal_id == internal_id) {
                notification = n;
                break;
            }
        }

        if (notification == null) {
            warning ("Notification not found: %s", internal_id);
            return false;
        }

        if (type == "action") {
            foreach (var button in notification.buttons) {
                if (button.action_name == action_name) {
                    parameter_type = button.action_target.get_type ();
                    return true;
                }
            }
        } else {
            switch (action_name) {
                case "default":
                    parameter_type = notification.default_action_target != null ? notification.default_action_target.get_type () : null;
                    return true;

                case "dismiss":
                    parameter_type = null;
                    return true;

                default:
                    return false;
            }
        }

        return true;
    }

    public void change_action_state (string action_name, Variant value) { }
}
