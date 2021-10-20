
/*
 * Copyright 2019 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

public class PortalsDemo.Views.AppChooser: Gtk.Grid {

    construct {
        margin = 12;
        row_spacing = 3;
        vexpand = true;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        orientation = Gtk.Orientation.VERTICAL;

        var title_label = new Granite.HeaderLabel ("AppChooser Portal");
        var subtitle_label = new Gtk.Label ("Interface for choosing an application: org.freedesktop.impl.portal.AppChooser") {
            margin_bottom = 24
        };

        var open_text_button = new Gtk.Button.with_label ("Open Text");
        open_text_button.clicked.connect (() => {
            choose_app_for_resource_name ("appchooser-demo.txt");
        });

        var open_image_button = new Gtk.Button.with_label ("Open Image");
        open_image_button.clicked.connect (() => {
            choose_app_for_resource_name ("appchooser-demo.png");
        });

        var open_pdf_button = new Gtk.Button.with_label ("Open PDF");
        open_pdf_button.clicked.connect (() => {
            choose_app_for_resource_name ("appchooser-demo.pdf");
        });

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL) {
            layout_style = Gtk.ButtonBoxStyle.START,
            spacing = 12
        };
        button_box.add (open_text_button);
        button_box.add (open_image_button);
        button_box.add (open_pdf_button);

        attach (title_label, 0, 0, 2);
        attach_next_to (subtitle_label, title_label, Gtk.PositionType.BOTTOM, 2);
        attach_next_to (button_box, subtitle_label, Gtk.PositionType.BOTTOM, 1);
    }

    private void choose_app_for_resource_name (string resource_name) {
        var choose_app_dialog = new Dialog ((Gtk.Window) get_toplevel (), resource_name);
        var app_info = choose_app_dialog.get_chosen_app_info ();
    }


    private class Dialog: Object {
        private Gtk.AppChooserDialog dialog;
        private Gtk.CheckButton check_default;

        public string file_name_to_open { get; construct; }
        public Gtk.Window parent { get; construct; }

        public Dialog (Gtk.Window? parent, string file_name_to_open) {
            Object (parent: parent, file_name_to_open: file_name_to_open);
        }

        construct {
            var resource_file = File.new_for_uri ("resource:///io/elementary/portals/demo/" + file_name_to_open);
            if (!resource_file.query_exists (null)) {
                warning ("Resource file '%s' not found.", file_name_to_open);
                return;
            }

            GLib.File file_to_open;
            try {
                file_to_open = File.new_for_path ("%s/%s".printf (Environment.get_tmp_dir (), file_name_to_open));
                resource_file.copy (file_to_open, GLib.FileCopyFlags.OVERWRITE);
            } catch (Error e) {
                warning ("Error copying resource file '%s': %s", file_name_to_open, e.message);
            }

            dialog = new Gtk.AppChooserDialog (
                parent,
                Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                file_to_open
            ) {
                deletable = false
            };

            var app_chooser = dialog.get_widget () as Gtk.AppChooserWidget;
            app_chooser.show_recommended = true;

            check_default = new Gtk.CheckButton.with_label ("Set as default") {
                active = true,
                margin_start = 12,
                margin_bottom = 6
            };
            check_default.show ();

            dialog.get_content_area ().add (check_default);
            dialog.show ();
        }

        public AppInfo? get_chosen_app_info () {
            GLib.AppInfo? app = null;

            int response = dialog.run ();
            if (response == Gtk.ResponseType.OK) {
                app = dialog.get_app_info ();
            }
            dialog.destroy ();

            return app;
        }
    }
}