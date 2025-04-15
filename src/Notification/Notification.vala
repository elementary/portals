
public class Notification.Notification : GLib.Object {
    public const string ACTION_TYPE_ACTION = "action";
    public const string ACTION_TYPE_INTERNAL = "internal";
    public const string ACTION_DISMISS = "dismiss";
    public const string ACTION_DEFAULT = "default";

    private const string ACTION_FORMAT = "%s+action+%s"; // interal id, action name
    private const string INTERNAL_ACTION_FORMAT = "%s+internal+%s"; // interal id, action name

    [Flags]
    public enum DisplayHint {
        TRANSIENT,
        TRAY,
        PERSISTENT,
        HIDE_ON_LOCK_SCREEN,
        HIDE_CONTENT_ON_LOCK_SCREEN,
        SHOW_AS_NEW
    }

    public struct Button {
        public string label;
        public string action_name;
        public Variant[] action_target;

        public Button (string internal_id, HashTable<string, Variant> data) {
            if ("label" in data) {
                label = data["label"].get_string ();
            }

            if ("action" in data) {
                action_name = ACTION_FORMAT.printf (internal_id, data["action"].get_string ());
            }

            if ("action-target" in data) {
                action_target = { data["action-target"] };
            } else {
                action_target = {};
            }
        }
    }

    public struct Data {
        public HashTable<string, Variant> raw_data;
        public string app_id;
        public string dismiss_action_name;
        public string default_action_name;
        public Variant[] default_action_target;
        public Button[] buttons;
        public DisplayHint display_hint;

        public Data (string internal_id, string _app_id, HashTable<string, Variant> _raw_data) {
            raw_data = _raw_data;
            app_id = _app_id;
            dismiss_action_name = INTERNAL_ACTION_FORMAT.printf (internal_id, "dismiss");

            if ("default-action" in raw_data) {
                default_action_name = ACTION_FORMAT.printf (internal_id, raw_data["default-action"].get_string ());

                if ("default-action-target" in raw_data) {
                    default_action_target = { raw_data["default-action-target"] };
                } else {
                    default_action_target = {};
                }
            } else {
                default_action_name = INTERNAL_ACTION_FORMAT.printf (internal_id, "default");
                default_action_target = {};
            }

            if ("buttons" in raw_data) {
                var raw_buttons = (HashTable<string, Variant>[]) raw_data["buttons"];

                buttons = new Button[raw_buttons.length];

                for (int i = 0; i < raw_buttons.length; i++) {
                    buttons[i] = Button (internal_id, raw_buttons[i]);
                }
            } else {
                buttons = new Button[0];
            }

            display_hint = 0;
        }
    }

    private static HashTable<string, unowned Notification> notifications_by_internal_id = new HashTable<string, unowned Notification> (str_hash, str_equal);
    private static uint internal_ids = 0;

    public static Notification? get_for_internal_id (string internal_id) {
        return notifications_by_internal_id[internal_id];
    }

    public Data data { get; construct; }

    public string internal_id { private get; construct; }
    public string app_id { get; construct; }
    public string id { get; construct; }

    public DisplayHint display_hint { get { return data.display_hint; } }

    public Notification (string app_id, string id, HashTable<string, Variant> raw_data) {
        var internal_id = "%u".printf (internal_ids++);
        Object (internal_id: internal_id, app_id: app_id, id: id, data: Data (internal_id, app_id, raw_data));
    }

    construct {
        notifications_by_internal_id[internal_id] = this;
    }

    ~Notification () {
        notifications_by_internal_id.remove (internal_id);
    }

    public string[] get_actions () {
        string[] actions = new string[data.buttons.length + 2];

        actions[0] = data.dismiss_action_name;
        actions[1] = data.default_action_name;

        for (int i = 0; i < data.buttons.length; i++) {
            actions[i + 2] = data.buttons[i].action_name;
        }

        return actions;
    }

    public bool query_action (
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

        if (name == data.dismiss_action_name) {
            parameter_type = null;
            return true;
        }

        if (name == data.default_action_name) {
            parameter_type = variant_type_from_maybe_array (data.default_action_target);
            return true;
        }

        foreach (var button in data.buttons) {
            if (button.action_name == name) {
                parameter_type = variant_type_from_maybe_array (button.action_target);
                return true;
            }
        }

        return false;
    }

    private unowned VariantType? variant_type_from_maybe_array (Variant[] arr) {
        if (arr.length == 0) {
            return null;
        } else {
            return arr[0].get_type ();
        }
    }
}
