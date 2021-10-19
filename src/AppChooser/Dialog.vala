/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.AppChooser")]
public class AppChooser.Dialog : Hdy.Window {
    public signal void choiced (string app_id);

    // The ID used to register this dialog on the DBusConnection
    public uint register_id { get; set; default = 0; }

    // The ID of the app sending the request
    public string app_id { get; construct; }

    // The object path of this specific request handler
    public ObjectPath handle { get; construct; }

    public string parent_window { get; construct; }

    // The app id that was selected the last time
    public string last_choice { get; construct; }

    // The content type to choose an application for
    public string content_type { get; construct ; }

    // The filename to choose an app for. That this is just a basename, without a path
    public string filename { get; construct; }

    private AppButton selected;
    private HashTable<string, AppButton> buttons;
    private Hdy.Carousel carousel;
    private weak Gtk.Box last_box;

    public Dialog (
        ObjectPath handle,
        string app_id,
        string parent_window,
        string last_choice,
        string content_type,
        string filename
    ) {
        Object (
            handle: handle,
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
        Hdy.init ();

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
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        var secondary_text = _("An application requested to open a file.");
        if (info != null) {
            _("“%s” requested to open a %s.").printf (info.get_display_name (), content_description);
        }

        var secondary_label = new Gtk.Label (secondary_text) {
            max_width_chars = 50,
            margin_bottom = 18,
            use_markup = true,
            wrap = true,
            xalign = 0
        };

        var mime_icon = new Gtk.Image () {
            gicon = content_icon ,
            icon_size = Gtk.IconSize.DIALOG
        };

        var overlay = new Gtk.Overlay () {
            valign = Gtk.Align.START
        };
        overlay.add (mime_icon);

        if (info != null) {
            var badge = new Gtk.Image.from_gicon (info.get_icon (), Gtk.IconSize.LARGE_TOOLBAR) {
                halign = Gtk.Align.END,
                valign = Gtk.Align.END
            };

            overlay.add_overlay (badge);
        }

        carousel = new Hdy.Carousel () {
            allow_long_swipes = true,
            allow_mouse_drag = true,
            expand = true
        };

        var switcher = new Hdy.CarouselIndicatorDots () {
            carousel = carousel
        };

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

        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (secondary_label, 1, 1);
        grid.attach (carousel, 0, 3, 2);
        grid.attach (switcher, 0, 4, 2);
        grid.attach (button_box, 1, 5);

        var window_handle = new Hdy.WindowHandle ();
        window_handle.add (grid);

        add (window_handle);

        if (parent_window != "") {
            var parent = ExternalWindow.from_handle (parent_window);

            if (parent == null) {
                warning ("Failed to associate portal window with parent window %s", parent_window);
            } else {
                parent.set_parent_of (get_window ());
            }
        }

        select.clicked.connect (() => choiced (selected.info.get_id ()));
        cancel.clicked.connect (() => choiced (""));

        // close the dialog after a selection;
        choiced.connect_after (() => destroy ());

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
        buttons[choice] = new AppButton (choice);
        buttons[choice].clicked.connect (() => {
            selected = buttons[choice];
        });

        last_box.add (buttons[choice]);
    }


    [DBus (visible = false)]
    public void update_choices (string[] choices) {
        foreach (var choice in choices) {
            if (!(choice in buttons)) {
                add_choice (choice);
            }
        }

        if (last_choice != null && last_choice != "" && !(last_choice in buttons)) {
            if (carousel.n_pages == 0) {
                create_box ();
            }

            add_choice (last_choice);
            selected = buttons[last_choice];
            buttons[last_choice].grab_focus ();
        }
    }

    [DBus (name = "Close")]
    public void on_close () throws DBusError, IOError {
        destroy ();
    }
}
