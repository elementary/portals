/*
 *
 *
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class Access.Dialog : Granite.MessageDialog {
    private DBusConnection connection;
    private string parent_handle;
    private uint register_id;

    private Gtk.Button grant_button;
    private Gtk.Button deny_button;
    private Gtk.Box box;

    public string deny_label {
        set {
            deny_button.label = value;
        }
    }

    public string grant_label {
        set {
            grant_button.label = value;
        }
    }

    public HashTable<unowned string, string> choices { get; private set; }

    public Dialog (
        DBusConnection conn,
        ObjectPath handle,
        string app_id,
        string parent_window,
        string title,
        string sub_title,
        string body
    ) {
        Object (
            primary_text: title,
            secondary_text: sub_title,
            image_icon : new ThemedIcon ("dialog-information"),
            buttons: Gtk.ButtonsType.NONE,
            resizable: false,
            skip_taskbar_hint: true
        );

        connection = conn;
        try {
            register_id = connection.register_object<Dialog> (handle, this);
        } catch (Error e) {
            critical (e.message);
        }

        if (body != "") {
            box.pack_start (new Gtk.Label (body), false, false);
        }

        realize ();

        if (parent_window != "") {
            var parent = ExternalWindow.from_handle (parent_window);
            if (parent == null) {
                warning ("Failed to associate portal window with parent window %s", parent_handle);
            } else {
                parent.set_parent_of (get_window ());
            }
        }
    }

    construct {
        set_keep_above (true);
        modal = true;

        deny_button = add_button (_("Deny Access"), Gtk.ResponseType.CANCEL) as Gtk.Button;

        grant_button = add_button (_("Grant Access"), Gtk.ResponseType.OK) as Gtk.Button;
        grant_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        set_default (deny_button);

        choices = new HashTable<unowned string, string> (str_hash, str_equal);
        box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        custom_bin.add (box);

        response.connect_after (() => {
            destroy ();
        });

        destroy.connect (() => {
            if (register_id != 0) {
                connection.unregister_object (register_id);
                register_id = 0;
            }
        });
    }

    [DBus (visible = false)]
    public void add_choice (Variant choice) {
        unowned string id, label, selected;
        Variant options;

        choice.get ("(&s&s@a(ss)&s)", out id, out label, out options, out selected);

        if (options.n_children () > 0) {
            var group_label = new Gtk.Label (label);
            Gtk.RadioButton group = null;

            group_label.get_style_context ().add_class ("dim-label");
            box.add (group_label);

            for (size_t i = 0; i < options.n_children (); ++i) {
                unowned string option_id, option_label;

                options.get_child (i, "(&s&s)", out option_id, out option_label);
                var button = new Gtk.RadioButton.with_label_from_widget (group, option_label) {
                    active = selected == option_id
                };

                button.set_data<string> ("choice-id", id);
                button.set_data<string> ("option-id", option_id);
                button.toggled.connect (() => {
                    if (button.active) {
                        choices.set (
                            button.get_data<string> ("choice-id"),
                            button.get_data<string> ("option-id")
                        );
                    }
                });

                button.show ();
                box.add (button);

                if (group == null) {
                    group = button;
                }
            }
        } else {
            var button = new Gtk.CheckButton.with_label (label) {
                active = bool.parse (selected)
            };

            button.set_data<string> ("choice-id", id);
            button.toggled.connect (() => {
                choices.set (
                    button.get_data<string> ("choice-id"),
                    button.active.to_string ()
                );
            });

            button.show_all ();
            box.add (button);
        }

        choices[id] = selected;
    }

    [DBus (name = "Close")]
    public void on_close () throws DBusError, IOError {
        response (Gtk.ResponseType.DELETE_EVENT);
    }
}
