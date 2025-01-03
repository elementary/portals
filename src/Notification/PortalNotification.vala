
public class Notification.Notification : GLib.Object {
    public const string ACTION_GROUP_NAME = "action";
    public const string ACTION_PREFIX = ACTION_GROUP_NAME + ".";

    public class Button : Object {
        public string label;
        public string action_name;
        public Variant? action_target = null;
    }

    [Flags]
    public enum DisplayHint {
        TRANSIENT,
        TRAY,
        PERSISTENT,
        HIDE_ON_LOCK_SCREEN,
        HIDE_CONTENT_ON_LOCK_SCREEN,
        SHOW_AS_NEW
    }

    public unowned Portal portal { get; construct; }

    public string id { get; construct; }

    public string app_id { get; construct; }

    public HashTable<string, Variant> data { get; construct; }

    /**
     * The title of the notification, always uses markup.
     */
    public string title { get; private set; }

    /**
     * The body of the notification, always uses markup.
     */
    public string body { get; private set; }

    public string time { get; private set; } // with 60 second timeout

    public Icon primary_icon { get; private set; }
    public Icon? secondary_icon { get; private set; }

    public NotificationPriority priority { get; private set; default = NORMAL; }

    public string default_action_name { get; construct; }
    public Variant? default_action_target { get; construct; }

    public ListStore buttons { get; private set; }

    public DisplayHint display_hint { get; private set; }

    private ActionEntry[] action_entries;

    public Notification (string app_id, string id, HashTable<string, Variant> data, Portal portal) {
        Object (app_id: app_id, id: Portal.ID_FORMAT.printf (app_id, id), data: data, portal: portal);
    }

    ~Notification () {
        portal.actions.remove_action_entries (action_entries);
    }

    construct {
        buttons = new ListStore (typeof (Button));

        if ("title" in data) {
            title = data["title"].get_string ();
        }

        if ("body" in data) {
            body = data["body"].get_string ();
        }

        if ("markup-body" in data) {
            body = data["markup-body"].get_string ();
        }

        var desktop_app_info = new DesktopAppInfo (app_id + ".desktop");

        primary_icon = desktop_app_info.get_icon ();

        if ("icon" in data) {
            // do some shit
        }

        if ("priority" in data) {
            var priority = data["priority"].get_string ();

            switch (priority) {
                case "low":
                    this.priority = LOW;
                    break;

                case "normal":
                default:
                    this.priority = NORMAL;
                    break;
            }
        }

        ActionEntry default_action_entry;

        if ("default-action" in data) {
            var default_action_name = Portal.ACTION_FORMAT.printf (id, data["default-action"].get_string ());

            string? default_action_parameter = null;
            if ("default-action-target" in data) {
                default_action_parameter = default_action_entry.parameter_type = data["default-action-target"].get_type_string ();
            }

            default_action_entry = portal.create_action_entry (default_action_name, default_action_parameter);

            this.default_action_name = default_action_name;
            this.default_action_target = data["default-action-target"];
        } else {
            default_action_entry = portal.create_action_entry (Portal.INTERNAL_ACTION_FORMAT.printf (id, "default"), null);
            default_action_name = default_action_entry.name;
        }

        if ("buttons" in data) {
            var buttons = (HashTable<string, Variant>[]) data["buttons"];

            foreach (var button_data in buttons) {
                var button = new Button ();

                if ("label" in button_data) {
                    button.label = button_data["label"].get_string ();
                }

                if ("action" in button_data) {
                    button.action_name = Portal.ACTION_FORMAT.printf (id, button_data["action"].get_string ());
                }

                if ("action-target" in button_data) {
                    button.action_target = button_data["action-target"];
                }

                this.buttons.append (button);

                action_entries += portal.create_action_entry (button.action_name, button.action_target != null ? button.action_target.get_type_string () : null);
            }
        }

        portal.actions.add_action_entries (action_entries, portal);
    }

    public void play_sound () {

    }
}
