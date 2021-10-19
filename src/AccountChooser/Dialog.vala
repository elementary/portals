/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class AccountChooser.Dialog : Hdy.Window {
    public string app_id { get; construct; }
    private DBusConnection connection;
    private uint register_id;

    private HashTable<string, AccountButton> buttons;
    private AccountButton selected;

    private Hdy.Carousel carousel;
    private weak Gtk.Box last_box;

    public signal void choiced (string account_id);

    public Dialog (DBusConnection conn, ObjectPath handle, string app_id, string parent_window) {
        Object (app_id: app_id, default_width: 700, resizable: false);
        connection = conn;

        try {
            register_id = connection.register_object<Dialog> (handle, this);
        } catch (Error e) {
            critical (e.message);
        }

        realize ();

        if (parent_window != "") {
            var parent = ExternalWindow.from_handle (parent_window);

            if (parent == null) {
                warning ("Failed to associate portal window with parent window %s", parent_window);
            } else {
                parent.set_parent_of (get_window ());
            }
        }
    }

    construct {
        buttons = new HashTable<string, AccountButton> (str_hash, str_equal);
        AppInfo? info = app_id == "" ? null : new DesktopAppInfo (app_id + ".desktop");
        Hdy.init ();

        var handle = new Hdy.WindowHandle ();

        var cancel = new Gtk.Button.with_label ("Cancel");
        var select = new Gtk.Button.with_label ("Select");
        select.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL) {
            layout_style = Gtk.ButtonBoxStyle.END,
            valign = Gtk.Align.END,
            margin_top = 12,
            expand = true,
            spacing = 6
        };

        button_box.add (cancel);
        button_box.add (select);

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            column_spacing = 12,
            row_spacing = 6,
            margin = 12
        };

        grid.attach (button_box, 0, 0);

        handle.add (grid);
        add (handle);

        select.clicked.connect (() => choiced (selected.account_id));
        cancel.clicked.connect (() => choiced (""));

        // close the dialog after a selection;
        choiced.connect_after (() => destroy ());

        destroy.connect (() => {
            if (register_id != 0) {
                connection.unregister_object (register_id);
                register_id = 0;
            }
        });

        create_box ();
    }

    private void create_box () {
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.add.connect_after (() => {
            if (box.get_children ().length () == 5) {
                create_box ();
            }
        });

        carousel.insert (box, -1);
        last_box = box;
    }

    private void add_choice (string choice) {
        var button = new AccountButton (choice);
        button.clicked.connect (() => { selected = button; });
        buttons[choice] = button;
        last_box.add (button);
    }

    [DBus (visible = false)]
    public void update_choices (string[] choices) {
        foreach (var choice in choices) {
            if (!(choice in buttons)) {
                add_choice (choice);
            }
        }
    }

    [DBus (name = "Close")]
    public void on_close () throws DBusError, IOError {
        destroy ();
    }
}
