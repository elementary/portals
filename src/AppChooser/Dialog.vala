/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class AppChooser.Dialog : Hdy.Window {
    public string app_id { get; construct; }
    private DBusConnection connection;
    private uint register_id;

    private HashTable<string, AppButton> buttons;
    private AppButton selected;

    private Gtk.Image mime_icon;
    private Gtk.Label primary_label;
    private Gtk.Label secondary_label;

    private Hdy.Carousel carousel;
    private weak Gtk.Box last_box;

    public string filename {
        set {
            primary_label.label = "Open '%s' With\u2026".printf (value);
        }
    }

    public string content_type {
        set {
            mime_icon.gicon = ContentType.get_icon (value);
            secondary_label.label = secondary_label.label.replace (
                "a file",
                "a %s".printf (ContentType.get_description (value))
            );
        }
    }

    public string last_choice {
        set {
            if (value != null && value != "" && !(value in buttons)) {
                if (carousel.n_pages == 0) {
                    create_box ();
                }

                add_choice (value);
                selected = buttons[value];
                buttons[value].grab_focus ();
            }
        }
    }

    public signal void choiced (string app_id);

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
        buttons = new HashTable<string, AppButton> (str_hash, str_equal);
        AppInfo? info = app_id == "" ? null : new DesktopAppInfo (app_id + ".desktop");
        Hdy.init ();

        var handle = new Hdy.WindowHandle ();

        primary_label = new Gtk.Label ("Open File With\u2026") {
             max_width_chars = 50,
             selectable = false,
             hexpand = true,
             wrap = true,
             xalign = 0
        };
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_PRIMARY_LABEL);

        secondary_label = new Gtk.Label (null) {
            label = "%s requested to open a file. ".printf (info.get_display_name () ?? "An Application"),
            max_width_chars = 50,
            margin_bottom = 18,
            use_markup = true,
            wrap = true,
            xalign = 0

        };
        secondary_label.label += "Choose one of the applications below to handle it";

        mime_icon = new Gtk.Image () {
            gicon = ContentType.get_icon ("text/plain"),
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

        handle.add (grid);
        add (handle);

        select.clicked.connect (() => choiced (selected.info.get_id ()));
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
        var button = new AppButton (choice);
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
