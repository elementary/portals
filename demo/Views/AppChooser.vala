
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
        var resource_file = File.new_for_uri ("resource:///io/elementary/portals/demo/" + resource_name);
        if (!resource_file.query_exists (null)) {
            warning ("Resource file '%s' not found.", resource_name);
            return;
        }

        // Generate unknown file extension appendix to make sure we don't have a default
        // application set for this, which in turn forces the AppChooser portal to be
        // opened for each and every request:
        var unknown_file_extension_appendix = "%lx".printf ((long) new GLib.DateTime.now_utc ().to_unix ());

        GLib.File file_to_open;
        try {
            file_to_open = File.new_for_path ("%s/%s%s".printf (
                Environment.get_tmp_dir (),
                resource_name,
                unknown_file_extension_appendix
            ));
            resource_file.copy (file_to_open, GLib.FileCopyFlags.OVERWRITE);
        } catch (Error e) {
            warning ("Error copying resource file '%s': %s", resource_name, e.message);
            return;
        }

        var file_uri_to_open = file_to_open.get_uri ();
        try {
            GLib.AppInfo.launch_default_for_uri (file_uri_to_open, null);
        } catch (Error e) {
            warning ("Error open file uri '%s': %s", file_uri_to_open, e.message);
            return;
        }
    }
}
