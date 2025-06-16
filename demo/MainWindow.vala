/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class PortalsDemo.MainWindow: Gtk.ApplicationWindow {

    public MainWindow (Gtk.Application application) {
        Object (application: application);
    }

    construct {
        var appchooser_view = new Views.AppChooser ();

        var main_stack = new Gtk.Stack ();
        main_stack.add_titled (appchooser_view, "appchooser", "AppChooser");

        var stack_sidebar = new Gtk.StackSidebar ();
        stack_sidebar.stack = main_stack;

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.add1 (stack_sidebar);
        paned.add2 (main_stack);

        var headerbar = new Gtk.HeaderBar ();
        headerbar.get_style_context ().add_class ("default-decoration");
        headerbar.show_close_button = true;

        add (paned);
        set_default_size (900, 600);
        set_size_request (750, 500);
        set_titlebar (headerbar);
        title = "Portals Demo";

        show_all ();
    }
}
