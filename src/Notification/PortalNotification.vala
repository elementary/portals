
public class Notification.PortalNotification : GLib.Object {
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

    public signal void dismissed (string id);
    public signal void activate_action (string name, Variant? target);

    public string id { get; construct; }

    public string app_id { get; construct; }

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

    public SimpleActionGroup actions { get; private set; }
    public ListStore buttons { get; private set; }

    public DisplayHint display_hint { get; private set; }

    public PortalNotification (string app_id, string id, HashTable<string, Variant> data) {
        Object (app_id: app_id, id: Portal.ID_FORMAT.printf (app_id, id));

        replace (data);
    }

    construct {
        buttons = new ListStore (typeof (Button));
        actions = new SimpleActionGroup ();
    }

    public void replace (HashTable<string, Variant> data) {
        buttons.remove_all ();

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

        if ("default-action" in data) {
            var default_action = new SimpleAction ("default", null);
            actions.add_action (default_action);

            if ("default-action-target" in data) {
                default_action.activate.connect (() => activate_action (data["default-action"].get_string (), data["default-action-target"]));
            } else {
                default_action.activate.connect (() => activate_action (data["default-action"].get_string (), null));
            }
        }

        if ("buttons" in data) {
            var buttons = (HashTable<string, Variant>[]) data["buttons"];

            foreach (var button_data in buttons) {
                var button = new Button ();

                if ("label" in button_data) {
                    button.label = button_data["label"].get_string ();
                }

                if ("action" in button_data) {
                    button.action_name = button_data["action"].get_string ();
                }

                if ("action-target" in button_data) {
                    button.action_target = button_data["action-target"];
                }

                this.buttons.append (button);
                var action = new SimpleAction (button.action_name, button.action_target != null ? button.action_target.get_type () : null);
                actions.add_action (action);
                action.activate.connect ((target) => activate_action (button.action_name, target));
            }
        }
    }

    public void play_sound () {

    }

    public void dismiss () {
        dismissed (id);
    }
}
