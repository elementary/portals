public class Notification.Widget : Granite.Bin {
    public Notification notification { get; construct; }

    public Gtk.Label time_label { get; construct; }

    private Gtk.FlowBox button_box;

    public Widget (Notification notification) {
        Object (notification: notification);
    }

    construct {
        var primary_icon = new Gtk.Image ();
        notification.bind_property ("primary-icon", primary_icon, "gicon", SYNC_CREATE);

        var secondary_icon = new Gtk.Image ();
        bind_with_visible ("secondary-icon", secondary_icon, "gicon");

        var icon_overlay = new Gtk.Overlay () {
            child = primary_icon
        };
        icon_overlay.add_overlay (secondary_icon);

        var title_label = new Gtk.Label (null) {
            halign = START,
            margin_start = 12,
            margin_end = 12,
            margin_top = 12,
            margin_bottom = 6,
            wrap = true,
            max_width_chars = 50,
            ellipsize = END,
            use_markup = true
        };
        notification.bind_property ("title", title_label, "label", SYNC_CREATE);

        time_label = new Gtk.Label (null);
        notification.bind_property ("time", time_label, "label", SYNC_CREATE);

        var body_label = new Gtk.Label (null) {
            halign = START,
            margin_start = 12,
            margin_end = 12,
            margin_top = 12,
            margin_bottom = 6,
            wrap = true,
            max_width_chars = 50,
            ellipsize = END,
            use_markup = true
        };
        notification.bind_property ("body", body_label, "label", SYNC_CREATE);

        button_box = new Gtk.FlowBox () {
            halign = END,
            margin_start = 12,
            margin_end = 12,
            margin_top = 6,
            margin_bottom = 6,
            selection_mode = NONE,
            homogeneous = true
        };
        button_box.bind_model (notification.buttons, create_button_func);

        var grid = new Gtk.Grid ();
        grid.attach (icon_overlay, 0, 0, 1, 2);
        grid.attach (title_label, 1, 0, 1, 1);
        grid.attach (time_label, 2, 0, 1, 1);
        grid.attach (body_label, 1, 1, 2, 1);
        grid.attach (button_box, 1, 2, 2, 1);

        child = grid;

        var gesture_click = new Gtk.GestureClick ();
        gesture_click.pressed.connect (() => activate_action_variant (notification.default_action_name, notification.default_action_target));
        add_controller (gesture_click);
    }

    private Gtk.Widget create_button_func (Object obj) {
        var button = (Notification.Button) obj;
        return new Gtk.Button.with_label (button.label) {
            action_name = Notification.ACTION_PREFIX + button.action_name,
            action_target = button.action_target
        };
    }

    private void bind_with_visible (string property, Gtk.Widget widget, string widget_property) {
        notification.bind_property (property, widget, widget_property, SYNC_CREATE);
    }
}
