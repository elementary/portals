public class ScreenCast.SelectionRow : Gtk.ListBoxRow {
    public SourceType source_type { get; construct; }
    public Variant id { get; construct; }
    public string label { get; construct; }
    public Icon? icon { get; construct; }
    public Gtk.CheckButton? group { get; construct; }

    public Gtk.CheckButton check_button { get; construct; }

    public bool selected { get; set; default = false; }

    public SelectionRow (SourceType source_type, Variant id, string label, Icon? icon, Gtk.CheckButton? group) {
        Object (
            source_type: source_type,
            id: id,
            label: label,
            icon: icon,
            group: group
        );
    }

    construct {
        var box = new Gtk.Box (HORIZONTAL, 6);

        check_button = new Gtk.CheckButton ();
        box.append (check_button);
        check_button.set_group (group);

        if (icon != null) {
            box.append (new Gtk.Image.from_gicon (icon));
        }

        box.append (new Gtk.Label (label) { ellipsize = MIDDLE });

        child = box;

        check_button.bind_property ("active", this, "selected", DEFAULT);
    }
}