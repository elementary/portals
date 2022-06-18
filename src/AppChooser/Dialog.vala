/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class AppChooser.Dialog : Gtk.Window {
    public signal void choiced (string app_id);

    // The ID used to register this dialog on the DBusConnection
    public uint register_id { get; set; default = 0; }

    // The ID of the app sending the request
    public string app_id { get; construct; }

    public string parent_window { get; construct; }

    // The app id that was selected the last time
    public string last_choice { get; construct; }

    // The content type to choose an application for
    public string content_type { get; construct ; }

    // The filename to choose an app for. That this is just a basename, without a path
    public string filename { get; construct; }

    private HashTable<string, AppButton> buttons;
    private Gtk.Button open_button;
    private Gtk.ListBox listbox;

    public Dialog (
        string app_id,
        string parent_window,
        string last_choice,
        string content_type,
        string filename
    ) {
        Object (
            app_id: app_id,
            parent_window: parent_window,
            last_choice: last_choice,
            content_type: content_type,
            filename: filename
        );
    }

    construct {
        buttons = new HashTable<string, AppButton> (str_hash, str_equal);
        AppInfo? info = app_id == "" ? null : new DesktopAppInfo (app_id + ".desktop");

        var primary_text = "Open file with…";
        if (filename != "") {
            primary_text = "Open “%s” with…".printf (filename);
        }

        var content_description = ContentType.get_description ("text/plain");
        var content_icon = ContentType.get_icon ("text/plain");
        if (content_type != "") {
            content_description = ContentType.get_description (content_type);
            content_icon = ContentType.get_icon (content_type);
        }

        var primary_label = new Gtk.Label (primary_text) {
             max_width_chars = 50,
             selectable = false,
             hexpand = true,
             wrap = true,
             xalign = 0
        };
        primary_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var secondary_text = _("An application requested to open a %s.").printf (content_description);
        if (info != null) {
            secondary_text = _("“%s” requested to open a %s.").printf (info.get_display_name (), content_description);
        }

        var secondary_label = new Gtk.Label (secondary_text) {
            max_width_chars = 50,
            margin_bottom = 18,
            use_markup = true,
            wrap = true,
            xalign = 0
        };

        var mime_icon = new Gtk.Image () {
            gicon = content_icon,
            icon_size = Gtk.IconSize.LARGE
        };

        var overlay = new Gtk.Overlay () {
            valign = Gtk.Align.START
        };
        overlay.child = mime_icon;

        if (info != null) {
            var badge = new Gtk.Image.from_gicon (info.get_icon ()) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.END
            };

            overlay.add_overlay (badge);
        }

        var placeholder = new Granite.Placeholder (_("No installed apps can open %s").printf (content_description)) {
            description = _("New apps can be installed from AppCenter"),
            icon = new ThemedIcon ("application-default-icon")
        };
        placeholder.show ();

        listbox = new Gtk.ListBox () {
            vexpand = true
        };
        listbox.set_placeholder (placeholder);

        var scrolled_window = new Gtk.ScrolledWindow ();
        scrolled_window.child = listbox;

        var frame = new Gtk.Frame (null);
        frame.child = scrolled_window;

        var cancel = new Gtk.Button.with_label (_("Cancel"));

        open_button = new Gtk.Button.with_label (_("Open")) {
            receives_default = true
        };
        open_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            halign = Gtk.Align.END,
            margin_top = 12
        };

        button_box.append (cancel);
        button_box.append (open_button);

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            column_spacing = 12,
            row_spacing = 6,
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };

        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (secondary_label, 1, 1);
        grid.attach (frame, 0, 3, 2);
        grid.attach (button_box, 1, 4);

        var window_handle = new Gtk.WindowHandle ();
        window_handle.child = grid;

        child = window_handle;

        default_height = 400;
        default_width = 350;
        modal = true;

        set_decorated (false);
        set_default_widget (open_button);

        if (parent_window == "") {
            warning ("Unknown parent window: The portal dialog might appear at the wrong spot because we can't assign a transient parent.");

        } else {
            ((Gtk.Widget) this).realize.connect (() => {
                try {
                    ExternalWindow.from_handle (parent_window).set_parent_of (get_surface ());
                } catch (Error e) {
                    warning ("Failed to associate portal window with parent %s: %s", parent_window, e.message);
                }
            });
        }

        listbox.row_activated.connect ((row) => {
            choiced (((AppChooser.AppButton) row).app_id);
        });

        open_button.clicked.connect (() => choiced (((AppChooser.AppButton) listbox.get_selected_row ()).app_id));
        cancel.clicked.connect (() => choiced (""));

        // close the dialog after a selection;
        choiced.connect_after (() => destroy ());
    }

    private void add_choice (string choice) {
        buttons[choice] = new AppButton (choice);
        listbox.append (buttons[choice]);
    }


    [DBus (visible = false)]
    public void update_choices (string[] choices) {
        foreach (var choice in choices) {
            if (!(choice in buttons) && choice != app_id) {
                add_choice (choice);
            }
        }
        listbox.show ();

        if (last_choice != "" && !(last_choice in buttons) && last_choice != app_id) {
            add_choice (last_choice);
            buttons[last_choice].grab_focus ();
        }

        open_button.sensitive = listbox.get_row_at_index (0) != null;
    }

    [DBus (name = "Close")]
    public void on_close () throws DBusError, IOError {
        destroy ();
    }
}
