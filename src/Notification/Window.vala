/*
* SPDX-License-Identifier: GPL-3.0-or-later
* SPDX-FileCopyrightText: {{YEAR}} {{DEVELOPER_NAME}} <{{DEVELOPER_EMAIL}}>
*/

public class Notification.MainWindow : Gtk.Window {
    public Portal portal { get; construct; }

    public MainWindow (Portal portal) {
        Object (
            default_height: 500,
            default_width: 500,
            title: _("My App Name"),
            portal: portal
        );
    }

    construct {
        var list_box = new Gtk.ListBox ();
        list_box.bind_model (portal.notifications, create_widget_func);

        child = list_box;
        titlebar = new Gtk.Grid () { visible = false };
    }

    private Gtk.Widget create_widget_func (Object obj) {
        var notification = (Notification) obj;
        var widget = new Widget (notification);
        return widget;
    }
}
