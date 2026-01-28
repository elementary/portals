/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class AppChooser.Dialog : PortalDialog {
    public signal void choiced (string app_id);

    // The ID used to register this dialog on the DBusConnection
    public uint register_id { get; set; default = 0; }

    // The ID of the app sending the request
    public string app_id { get; construct; }

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
        string last_choice,
        string content_type,
        string filename
    ) {
        Object (
            app_id: app_id,
            last_choice: last_choice,
            content_type: content_type,
            filename: filename
        );
    }

    construct {
        buttons = new HashTable<string, AppButton> (str_hash, str_equal);
        AppInfo? info = app_id == "" ? null : new DesktopAppInfo (app_id + ".desktop");

        title = _("Open file with…");
        if (filename != "") {
            title = _("Open “%s” with…").printf (filename);
        }

        var content_description = ContentType.get_description ("text/plain");
        var image_icon = ContentType.get_icon ("text/plain");
        if (content_type != "") {
            content_description = ContentType.get_description (content_type);
            image_icon = ContentType.get_icon (content_type);
        }

        secondary_text = _("An application requested to open a %s.").printf (content_description);
        if (info != null) {
            secondary_text = _("“%s” requested to open a %s.").printf (info.get_display_name (), content_description);
        }

        if (info != null) {
            badge_icon = info.get_icon ();
        }

        var placeholder = new Granite.Placeholder (_("No installed apps can open %s").printf (content_description)) {
            description = _("New apps can be installed from AppCenter"),
            icon = new ThemedIcon ("application-default-icon")
        };

        listbox = new Gtk.ListBox () {
            vexpand = true
        };
        listbox.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        listbox.set_placeholder (placeholder);

        var scrolled_window = new Gtk.ScrolledWindow () {
            child = listbox
        };

        var frame = new Gtk.Frame (null) {
            child = scrolled_window,
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };

        var cancel_button = add_button (_("Cancel"));

        open_button = add_button (_("Open"));
        open_button.receives_default = true;
        open_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        content = frame;

        default_widget = open_button;

        listbox.row_activated.connect ((row) => {
            choiced (((AppChooser.AppButton) row).app_id);
        });

        open_button.clicked.connect (() => choiced (((AppChooser.AppButton) listbox.get_selected_row ()).app_id));
        cancel_button.clicked.connect (() => choiced (""));
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

        if (last_choice != "" && !(last_choice in buttons) && last_choice != app_id) {
            add_choice (last_choice);
            buttons[last_choice].grab_focus ();
        }

        open_button.sensitive = listbox.get_row_at_index (0) != null;
    }

    [DBus (name = "Close")]
    public void on_close () throws DBusError, IOError {
        choiced ("");
    }
}
