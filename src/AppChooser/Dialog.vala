/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class AppChooser.Dialog : Hdy.Window {
    public signal void chosen (string app_id);

    public string sender_app_id { get; construct; }

    private AppButton selected;
    private DBusConnection connection;
    private Gtk.Image mime_icon;
    private Gtk.Label primary_label;
    private Gtk.Label secondary_label;
    private HashTable<string, AppButton> buttons;
    private Hdy.Carousel carousel;
    private uint register_id;
    private weak Gtk.Box last_box;

    public string filename {
        set {
            primary_label.label = "Open “%s” with…".printf (value);
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

    public Dialog (DBusConnection conn, ObjectPath handle, string sender_app_id, string parent_window) {
        Object (
            sender_app_id: sender_app_id,
            resizable: false
        );

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
        Hdy.init ();

        buttons = new HashTable<string, AppButton> (str_hash, str_equal);
        AppInfo? info = sender_app_id == "" ? null : new DesktopAppInfo (sender_app_id + ".desktop");

        primary_label = new Gtk.Label ("Open file with…") {
             max_width_chars = 50,
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
            allow_mouse_drag = true
        };

        var switcher = new Hdy.CarouselIndicatorDots () {
            carousel = carousel
        };

        var cancel = new Gtk.Button.with_label ("Cancel") {
            halign = Gtk.Align.END
        };

        var grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            column_spacing = 12,
            row_spacing = 6,
            margin = 12
        };
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0);
        grid.attach (secondary_label, 1, 1);
        grid.attach (carousel, 0, 2, 2);
        grid.attach (switcher, 0, 3, 2);
        grid.attach (cancel, 1, 4);

        var handle = new Hdy.WindowHandle ();
        handle.add (grid);
        add (handle);

        cancel.clicked.connect (() => chosen (""));

        // close the dialog after a selection;
        chosen.connect_after (() => destroy ());

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

    private void add_choice (string app_id) {
        var button = new AppButton (app_id);
        buttons[app_id] = button;

        last_box.add (button);

        button.clicked.connect (() => {
            chosen (button.app_id);
        });
    }


    [DBus (visible = false)]
    public void update_choices (string[] app_ids) {
        foreach (var app_id in app_ids) {
            if (!(app_id in buttons) && app_id != sender_app_id) {
                add_choice (app_id);
            }
        }
    }

    [DBus (name = "Close")]
    public void on_close () throws DBusError, IOError {
        destroy ();
    }
}
