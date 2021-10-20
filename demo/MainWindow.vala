/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class PortalsDemo.MainWindow: Gtk.ApplicationWindow {

    public MainWindow (Gtk.Application application) {
        Object (application: application);
    }

    construct {
        title = "Portals Demo";

        default_height = 300;
        default_width = 300;
    }
}