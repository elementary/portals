
public class Notification.Notification : GLib.Object {
    public const string ACTION_GROUP_NAME = "action";
    public const string ACTION_PREFIX = ACTION_GROUP_NAME + ".";
    public const string ACTION_FORMAT = "%s+action+%s"; // interal id, action id
    public const string INTERNAL_ACTION_FORMAT = "%s+internal+%s"; // interal id, action id

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
        public Variant? action_target;

        public Button (HashTable<string, Variant> data) {
            if ("label" in data) {
                label = data["label"].get_string ();
            }

            if ("action" in data) {
                action_name = ACTION_FORMAT.printf (internal_id, data["action"].get_string ());
            }

            if ("action-target" in data) {
                action_target = data["action-target"];
            }
        }
    }

    public struct Data {
        public string internal_id;
        public string app_id;
        public string dismiss_action_name;
        public string default_action_name;
        public Variant? default_action_target;
        public Button[] buttons;
        public DisplayHint display_hint;
        public HashTable<string, Variant> raw_data;

        public Data (string internal_id, string app_id, HashTable<string, Variant> raw_data) {
            if ("default-action" in raw_data) {
                default_action_name = ACTION_FORMAT.printf (internal_id, raw_data["default-action"].get_string ());

                if ("default-action-target" in raw_data) {
                    default_action_target = raw_data["default-action-target"];
                }
            } else {
                default_action_name = INTERNAL_ACTION_FORMAT.printf (internal_id, "default");
            }

            if ("buttons" in raw_data) {
                var raw_buttons = (HashTable<string, Variant>[]) raw_data["buttons"];

                foreach (var raw_button in raw_buttons) {
                    buttons += Button (raw_button);
                }
            }
        }
    }

    public Data data { get; construct; }

    public string internal_id { get { return data.internal_id; } }

    public string dismiss_action_name { get { return data.dismiss_action_name; } }
    public string default_action_name { get { return data.default_action_name; } }
    public Variant? default_action_target { get { return data.default_action_target; } }
    public Button[] buttons { get { return data.buttons; } }

    public DisplayHint display_hint { get { return data.display_hint; } }

    public Notification (string internal_id, string app_id, HashTable<string, Variant> raw_data) {
        Object (data: Data (internal_id, app_id, raw_data));
    }
}
